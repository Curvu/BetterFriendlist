package {
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.geom.ColorTransform;
  import flash.text.TextField;
  import flash.text.TextFormat;
  
  public class txtbtn extends Sprite {
    public static const ENV:Boolean = abi.DEBUG > 2;

    public static const CLICK_SOUND:String = "Play_ui_button_select";
    private static const TEXT_FORMAT_DEFAULT:TextFormat = new TextFormat("Open Sans",9,16250871,false,false,false,false,false,"center");
    public var format:TextFormat;
    private var color_idle:ColorTransform;
    private var color_hover:ColorTransform;
    private var color_active:ColorTransform;
    private var color_disabled:ColorTransform;
    private var color_reset:ColorTransform;
    private var _text:TextField;
    private var bg:Shape;
    private var _disabled:Boolean = false;
    private var listeners:Array = [];
    private var _msg:String;
    private var _count:int = 0;

    public function txtbtn(w:int = 64, h:int = 12, txt:String = "", x:int = 0, y:int = 0) {
      super();
      this._msg = txt;
      this.format = TEXT_FORMAT_DEFAULT;
      this.color_idle = new ColorTransform(1,1,1,0.15,129,143,178);
      this.color_hover = new ColorTransform(1,1,1,0.5,129,143,178);
      this.color_active = new ColorTransform(1,1,1,0.5,80,91,119);
      this.color_disabled = new ColorTransform(1,1,1,0.75,26,26,36);
      this.color_reset = new ColorTransform(1,1,1,1);
      renderer.rectangle(this,0,0,w,h,0,0);
      this.bg = renderer.rectangle(new Shape(),0,0,w,h,0,1);
      renderer.outline(this.bg,0,0,w,h,0,1);
      this._text = renderer.text(0,0,this.format,"",true,txt);
      this._text.height = 14;
      this._text.y = txt == "x" ? -3 : -2;
      this._text.width = w;
      this.addChild(this.bg);
      this.addChild(this._text);
      this.addMouseEventListeners();
      this.bg.transform.colorTransform = this.color_idle;
      this.x = x;
      this.y = y;
      if(ENV) renderer.outline(this,0,0,w,h,16711935,1);
    }

    public function get count() : int {
      return this._count;
    }

    public function set count(num:int) : void {
      this._text.text = this._msg + " (" + num + ")";
      this.disabled = num == 0;
      this._count = num;
    }

    public function get disabled() : Boolean {
      return this._disabled;
    }

    public function set disabled(b:Boolean) : void {
      if(this._disabled != b) {
        this._disabled = b;
        if(b) {
          this.removeMouseEventListeners();
          this._text.textColor = 4605520;
          this.bg.transform.colorTransform = this.color_disabled;
        } else {
          this.addMouseEventListeners();
          this._text.textColor = 16250871;
          this.bg.transform.colorTransform = this.color_idle;
        }
      }
    }

    public function addClickListener(f:Function) : void {
      if(this.listeners.indexOf(f) == -1) this.listeners.push(f);
    }

    public function removeClickListener(f:Function) : void {
      var idx:int = this.listeners.indexOf(f);
      if(idx != -1) this.listeners.splice(idx,1);
    }

    private function addMouseEventListeners() : void {
      this.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
      this.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      this.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
      this.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
      this.addEventListener(MouseEvent.CLICK,this.onClick);
    }

    private function removeMouseEventListeners() : void {
      this.removeEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
      this.removeEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      this.removeEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
      this.removeEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
      this.removeEventListener(MouseEvent.CLICK,this.onClick);
    }

    private function onMouseOver() : void {
      this.bg.transform.colorTransform = this.color_hover;
    }

    private function onMouseOut() : void {
      this.bg.transform.colorTransform = this.color_idle;
    }

    private function onMouseDown() : void {
      ExternalInterface.call("POST_SOUND_EVENT",CLICK_SOUND);
      this.bg.transform.colorTransform = this.color_active;
    }

    private function onMouseUp() : void {
      this.bg.transform.colorTransform = this.color_hover;
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
