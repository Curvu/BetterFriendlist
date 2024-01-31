package {
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.geom.ColorTransform;
  import flash.text.TextField;
  import flash.text.TextFormat;

  public class KeyboardBtn extends Sprite {
    public static const CLICK_SOUND:String = "Play_ui_button_select";
    private static const TEXT_FORMAT_DEFAULT:TextFormat = new TextFormat("Open Sans",9,16250871,false,false,false,false,false,"center");
    public var format:TextFormat;
    private var _text:TextField;
    private var bg:Shape;
    private var _disabled:Boolean = false;
    private var listeners:Array = [];
    private var _msg:String;
    private var _count:int = 0;

    private var width:int;
    private var height:int;

    public function KeyboardBtn(w:int = 64, h:int = 12, txt:String = "", x:int = 0, y:int = 0) {
      super();

      this.width = w;
      this.height = h;

      this._msg = txt;
      this.format = TEXT_FORMAT_DEFAULT;

      renderer.rectangle(this, 0, 0, w, h, 0, 0);
      this.bg = renderer.rectangle(new Shape(), 0, 0, w, h, renderer.GRAY_28, 1);
      renderer.outline(this.bg, 0, 0, w, h, renderer.GRAY_12, 1);

      this._text = renderer.text(0, 1, this.format, "", true, txt);
      this._text.height = 14;
      this._text.width = w;

      this.addChild(this.bg);
      this.addChild(this._text);

      this.addMouseEventListeners();

      this.x = x;
      this.y = y;
    }

    private function addMouseEventListeners() : void {
      this.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
      this.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      this.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
      this.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
      this.addEventListener(MouseEvent.CLICK,this.onClick);
    }

    private function onMouseOver() : void {
      this.bg.graphics.clear();
      renderer.rectangle(this.bg, 0, 0, this.width, this.height, renderer.GRAY_28, 1);
      renderer.outline(this.bg, 0, 0, this.width, this.height, renderer.WHITE, 1);
    }

    private function onMouseOut() : void {
      this.bg.graphics.clear();
      renderer.rectangle(this.bg, 0, 0, this.width, this.height, renderer.GRAY_28, 1);
      renderer.outline(this.bg, 0, 0, this.width, this.height, renderer.GRAY_12, 1);
    }

    private function onMouseDown() : void {
      ExternalInterface.call("POST_SOUND_EVENT",CLICK_SOUND);
      this.bg.graphics.clear();
      renderer.rectangle(this.bg, 0, 0, this.width, this.height, renderer.GRAY_22, 1);
      renderer.outline(this.bg, 0, 0, this.width, this.height, renderer.WHITE, 1);
    }

    private function onMouseUp() : void {
      this.bg.graphics.clear();
      renderer.rectangle(this.bg, 0, 0, this.width, this.height, renderer.GRAY_28, 1);
      renderer.outline(this.bg, 0, 0, this.width, this.height, renderer.WHITE, 1);
    }

    private function onClick() : void {
      var idx:int = 0;
      var len:int = int(this.listeners.length);
      while(idx < len) {
        this.listeners[idx].call();
        idx++;
      }
    }

    public function get text() : String {
      return this._text.text;
    }
  }
}
