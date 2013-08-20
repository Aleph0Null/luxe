package levels;


import Luxe;

import luxe.Camera;
import luxe.Input;
import luxe.Rectangle;
import luxe.Text;
import luxe.utils.NineSlice;
import luxe.Sprite;
import luxe.Vector;
import luxe.Color;

import phoenix.Batcher;
import phoenix.geometry.Geometry;
import phoenix.BitmapFont;

import mode.Mode;

import motion.Actuate;

class Level01 extends Mode {

    public var mouse : Vector;
    public var dragging : Bool = false;
    public var mouse_down : Bool = false;
    public var start_drag : Vector;
    public var start_camera_drag : Vector;

    public var map : Sprite;
    public var hudbar : Sprite;
    public var money_text : Text;

    public var acq_button : Sprite;
    public var apt_button : Sprite;

    public var msg_dialog : Sprite;
    public var msg_text : Text;


    public var sign_list:Map<String,Vector>;
    public var sign_sprites:Map<String,Sprite>;
    public var sign_text_sprites:Map<String,Sprite>;

    public var map_scale : Float = 2;

    public var hud_batch : Batcher;
    public var hud_view : Camera;

    public function init() {
            
        start_drag = new Vector();
        start_camera_drag = new Vector();

        sign_list = new Map<String,Vector>();
        sign_sprites = new Map<String,Sprite>();
        sign_text_sprites = new Map<String,Sprite>();

        sign_list.set('university', new Vector(115,765) );
        sign_list.set('suburbia', new Vector(355,825) );

        hud_batch = new Batcher( Luxe.renderer, 'hud batcher' );
        hud_view = new Camera({name:'hud view'});

        hud_batch.view = hud_view.view;
        hud_batch.layer = 2; //1 is the default

        Luxe.renderer.add_batch( hud_batch );

        hudbar = new Sprite({
            depth:10,
            centered : false,
            pos : new Vector(),
            size : new Vector( Luxe.screen.w, 70 ),
            color : new Color().rgb(0x242424),
            batcher : hud_batch
        });

        msg_dialog = new Sprite({
            depth:10,
            centered : true,
            pos : new Vector(Luxe.screen.w/2, Luxe.screen.h/2),
            size : new Vector( 450, 300 ),
            color : new Color().rgb(0x242424),
            batcher : hud_batch
        });

        msg_text = new Text({
            depth : 11,
            bounds : new Rectangle( (Luxe.screen.w/2)-225, (Luxe.screen.h/2)-150 , 450,300),
            color : new Color().rgb(0xe7e7e7),
            text : 'message dialog',
            align : TextAlign.center,
            valign : TextAlign.center
        });

        acq_button = new Sprite({
            depth:11,
            centered : false,
            pos : new Vector(296,0),
            texture : Luxe.loadTexture('assets/map/hud/acq_inactive.png'),
            batcher : hud_batch
        });

        apt_button = new Sprite({
            depth:11,
            centered : false,
            pos : new Vector(523,0),
            texture : Luxe.loadTexture('assets/map/hud/apt_active.png'),
            batcher : hud_batch
        });


        for(_key in sign_list.keys()) {
                
                //fetch size
            var _sign_pos = sign_list.get(_key);

                //apply world scale to the position
            _sign_pos.multiplyScalar(map_scale);

                //the glow image
            var _sign_sprite = new Sprite({
                depth : 2,
                centered : true,
                origin : new Vector(64,450),
                texture : Luxe.loadTexture('assets/map/signs/sign.png'),
                pos : _sign_pos
            });

                //the text name
            var _sign_text_sprite = new Sprite({
                depth : 3,
                centered : true,
                texture : Luxe.loadTexture('assets/map/signs/'+ _key +'.png'),
                pos : _sign_pos 
            });

                //store for access and removal
            sign_sprites.set(_key, _sign_sprite);
            sign_text_sprites.set(_key, _sign_text_sprite);

        }//for each sign

        map = new Sprite({
            centered:false,
            size : new Vector(2048,2048),
            pos : new Vector(0,0),
            depth : 1,
            texture : Luxe.loadTexture('assets/map/map.png')
        });

        map.texture.filter = phoenix.Texture.FilterType.nearest;

        Luxe.camera.bounds = new Rectangle(0,0,2048,2048);
        Luxe.camera.pos = sign_list.get('university').clone().subtract( new Vector(Luxe.screen.w/2, Luxe.screen.h/2) );

    } //init

    var showing_dialog : Bool = false;
    public function show_dialog( text:String ) {

        if(msg_dialog.color.a == 0) {
            msg_dialog.visible = true;
        }

        Actuate.tween( msg_dialog.color, 0.5, { a:1 }).onComplete(function(){
            showing_dialog = true;
        });

        msg_text.text = text; 

    }

    public function hide_dialog() {
        Actuate.tween( msg_dialog.color, 0.5, { a:0 }).onComplete(function(){
            msg_dialog.visible = false;
            showing_dialog = false;
        });
    }


    public function destroy() {

        trace('destroying level 01');
        
        for(_key in sign_sprites.keys()) {
            sign_sprites.get(_key).destroy();
            sign_sprites.remove(_key);
            sign_text_sprites.get(_key).destroy();
            sign_text_sprites.remove(_key);
        }

        hudbar.destroy();
        hudbar = null;

        apt_button.destroy();        
        acq_button.destroy();

        apt_button = null;
        acq_button = null;

        map.destroy();
        map = null;

        Luxe.camera.bounds = null;

    }

    public function keydown(e) {
        
        if( e.value == Input.Keys.escape ) {
            game.modes.set('menu');
        }

    } //keydown

    public function mousedown(e) {

        mouse = new Vector(e.x,e.y);        
        mouse_down = true;

        if(showing_dialog) {
            return hide_dialog();
        }

            //in a short time from mousedown, check if it's still actually down before we start dragging
        haxe.Timer.delay(function(){
            if(mouse_down == false) return;
            if(!dragging) {
                dragging = true;
                start_drag.set(mouse.x, mouse.y);
                start_camera_drag.set(Luxe.camera.pos.x, Luxe.camera.pos.y);
            }
        }, 100);    

    }

    public function mouseup(e) {
        
        mouse = new Vector(e.x,e.y);
        mouse_down = false;

        if(dragging) {
            dragging = false;
        } else {
            Luxe.camera.center( Vector.Add( mouse, Luxe.camera.pos ) );
        }
    }

    public function mousemove(e) {

        mouse = new Vector(e.x,e.y);

        if(dragging) {
            var diffx = (e.x - start_drag.x);
            var diffy = (e.y - start_drag.y);
            Luxe.camera.pos.x = start_camera_drag.x - (diffx);
            Luxe.camera.pos.y = start_camera_drag.y - (diffy);
        } //if dragging

    }

    public function enter() {
       init();
    }

    public function leave() {
        Luxe.camera.pos = new Vector();
        destroy();
    }
}