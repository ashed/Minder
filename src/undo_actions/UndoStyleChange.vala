/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;

public class UndoStyleChange : UndoItem {

  private StyleAffects      _affects;
  private Array<Node>       _nodes;
  private Array<Connection> _conns;

  private enum StyleChangeType {
    LOAD = 0,
    UNDO,
    REDO
  }

  /* Constructor for a node name change */
  public UndoStyleChange( StyleAffects affects, DrawArea da ) {
    base( _( "style change" ) );
    _affects = affects;
    _nodes   = da.get_selected_nodes();
    _conns   = da.get_selected_connections();
  }

  /* Returns true if the given undo item matches our item */
  protected override bool matches( UndoItem item ) {
    UndoStyleChange other = (UndoStyleChange)item;
    if( (_affects == other._affects) && (_nodes.length == other._nodes.length) && (_conns.length == other._conns.length) ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) != other._nodes.index( i ) ) {
          return( false );
        }
      }
      for( int i=0; i<_conns.length; i++ ) {
        if( _conns.index( i ) != other._conns.index( i ) ) {
          return( false );
        }
      }
    }
    return( false );
  }

  protected void load_styles( DrawArea da ) {
    traverse_styles( da, StyleChangeType.LOAD );
  }

  private void traverse_styles( DrawArea da, StyleChangeType change_type ) {
    int index = 1;
    switch( _affects ) {
      case StyleAffects.ALL         :
        {
          var nodes = da.get_nodes();
          var conns = da.get_connections().connections;
          for( int i=0; i<nodes.length; i++ ) {
            set_style_for_tree( nodes.index( i ), change_type, ref index );
          }
          for( int i=0; i<conns.length; i++ ) {
            set_connection_style( conns.index( i ), change_type, ref index );
          }
          if( change_type == StyleChangeType.LOAD ) {
            Style new_style = new Style.templated();
            store_style_value( new_style, 0 );
            StyleInspector.styles.set_all_to_style( new_style );
          }
          da.current_changed( da );
        }
        break;
      case StyleAffects.SELECTED    :
        if( da.get_selected_nodes().length > 0 ) {
          for( int i=0; i<da.get_selected_nodes().length; i++ ) {
            set_node_style( da.get_selected_nodes().index( i ), change_type, ref index );
          }
          da.current_changed( da );
        }
        break;
      case StyleAffects.LEVEL0      :
      case StyleAffects.LEVEL1      :
      case StyleAffects.LEVEL2      :
      case StyleAffects.LEVEL3      :
      case StyleAffects.LEVEL4      :
      case StyleAffects.LEVEL5      :
      case StyleAffects.LEVEL6      :
      case StyleAffects.LEVEL7      :
      case StyleAffects.LEVEL8      :
      case StyleAffects.LEVEL9      :
        for( int i=0; i<da.get_nodes().length; i++ ) {
          set_style_for_level( da.get_nodes().index( i ), (1 << (int)_affects.level()), change_type, ref index, 0 );
        }
        if( change_type == StyleChangeType.LOAD ) {
          Style new_style = new Style.templated();
          store_style_value( new_style, 0 );
          StyleInspector.styles.set_levels_to_style( (1 << (int)_affects.level()), new_style );
        }
        da.current_changed( da );
        break;
      case StyleAffects.CURRENT     :
        if( _nodes.length > 0 ) {
          for( int i=0; i<_nodes.length; i++ ) {
            set_node_style( _nodes.index( i ), change_type, ref index );
          }
          da.current_changed( da );
        } else {
          for( int i=0; i<_conns.length; i++ ) {
            set_connection_style( _conns.index( i ), change_type, ref index );
          }
          da.current_changed( da );
        }
        break;
      case StyleAffects.CURRTREE    :
        set_style_for_tree( _nodes.index( 0 ).get_root(), change_type, ref index );
        da.current_changed( da );
        break;
      case StyleAffects.CURRSUBTREE :
        set_style_for_tree( _nodes.index( 0 ), change_type, ref index );
        da.current_changed( da );
        break;
    }
    da.changed();
    da.queue_draw();
  }

  private void set_style( Style old_style, Style new_style, StyleChangeType change_type, ref int index ) {
    switch( change_type ) {
      case StyleChangeType.LOAD :
        load_style_value( old_style );
        store_style_value( new_style, 0 );
        break;
      case StyleChangeType.UNDO :
        store_style_value( new_style, index++ );
        break;
      case StyleChangeType.REDO :
        store_style_value( new_style, 0 );
        break;
    }
  }

  private void set_node_style( Node node, StyleChangeType change_type, ref int index ) {
    Style new_style = new Style.templated();
    set_style( node.style, new_style, change_type, ref index );
    node.style = new_style;
  }

  private void set_connection_style( Connection conn, StyleChangeType change_type, ref int index ) {
    Style new_style = new Style.templated();
    set_style( conn.style, new_style, change_type, ref index );
    conn.style = new_style;
  }

  private void set_style_for_tree( Node node, StyleChangeType change_type, ref int index ) {
    set_node_style( node, change_type, ref index );
    for( int i=0; i<node.children().length; i++ ) {
      set_style_for_tree( node.children().index( i ), change_type, ref index );
    }
  }

  private void set_style_for_level( Node node, int levels, StyleChangeType change_type, ref int index, int level ) {
    if( (levels & (1 << level)) != 0 ) {
      set_node_style( node, change_type, ref index );
    }
    for( int i=0; i<node.children().length; i++ ) {
      set_style_for_level( node.children().index( i ), levels, change_type, ref index, ((level == 9) ? 9 : (level + 1)) );
    }
  }

  protected virtual void load_style_value( Style style ) {
    /* This method will be overridden */
  }

  protected virtual void store_style_value( Style style, int index ) {
    /* This method will be overridden */
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    traverse_styles( da, StyleChangeType.UNDO );
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    traverse_styles( da, StyleChangeType.REDO );
  }

  public override string to_string() {
    return( base.to_string() + ", affects: %s".printf( _affects.to_string() )  );
  }

}
