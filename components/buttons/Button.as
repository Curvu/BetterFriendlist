package components.buttons {
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.text.TextField;

  public class Button extends Sprite {
    public static const CLICK_SOUND:String = "Play_ui_button_select";

    private var color:uint = config.cfg.button_color;

    private var _text:TextField;
    private var body:Sprite;

    private var _msg:String;
    private var _count:int = 0;
    private var disabled:Boolean = false;

    private var listeners:Array = [];

    public function Button(w:int, h:int, txt:String = "", x:int = 0, y:int = 0, disabled:Boolean = false) {
      super();
      this.disabled = disabled;
      this._msg = txt;

      this.body = renderer.rectangle(new Sprite(), x, y, w, h, color);

      this._text = renderer.text(txt, 0, 0, 9, "center", w, h-2);
      this._text.x = x + (w - this._text.width) / 2;
      this._text.y = y + (h - this._text.height) / 2;

      this.addChild(this.body);
      this.addChild(this._text);

      this.addMouseEventListeners();
    }

    private function addMouseEventListeners() : void {
      this.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
      this.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      this.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
      this.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
      this.addEventListener(MouseEvent.CLICK,this.onClick);
    }

    private function onMouseOver(e:MouseEvent) : void {
      this.body.transform.colorTransform = renderer.hexToRGB(config.darken(color, 0.75));
    }

    private function onMouseOut(e:MouseEvent) : void {
      this.body.transform.colorTransform = renderer.hexToRGB(color);
    }

    private function onMouseDown(e:MouseEvent) : void {
      if (this.disabled) return;
      ExternalInterface.call("POST_SOUND_EVENT", CLICK_SOUND);
      this.body.transform.colorTransform = renderer.hexToRGB(config.darken(color, 0.65));
    }

    private function onMouseUp(e:MouseEvent) : void {
      if (this.disabled) return;
      this.body.transform.colorTransform = renderer.hexToRGB(color);
    }

    private function onClick(e:MouseEvent) : void {
      if (this.disabled) return;
      for each (var listener:Function in this.listeners)
        listener.call();
    }

    public function get text() : String {
      return this._text.text;
    }

    public function get count() : int {
      return this._count;
    }

    public function set count(num:int) : void {
      this._text.text = this._msg + " (" + num + ")";
      this._count = num;
    }
  }
}
