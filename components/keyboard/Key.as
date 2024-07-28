package components.keyboard {
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.text.TextField;

  public class Key extends Sprite {
    public static const CLICK_SOUND:String = "Play_ui_button_select";

    private var _text:TextField;
    private var border:Sprite;
    private var body:Sprite;

    private var listeners:Array = [];

    public function Key(w:int, h:int, txt:String = "", x:int = 0, y:int = 0) {
      super();

      this.border = renderer.rectangle(new Sprite(), x-1, y-1, w+2, h+2, renderer.GRAY_12);
      this.body = renderer.rectangle(new Sprite(), x, y, w, h, renderer.GRAY_28);

      this._text = renderer.text(txt, 0, 0, 9, "center", w, h-2);
      this._text.x = x + (w - this._text.width) / 2;
      this._text.y = y + (h - this._text.height) / 2;

      this.addChild(this.border);
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
      this.border.transform.colorTransform = renderer.hexToRGB(renderer.WHITE);
      this.body.transform.colorTransform = renderer.hexToRGB(renderer.GRAY_22);
    }

    private function onMouseOut(e:MouseEvent) : void {
      this.border.transform.colorTransform = renderer.hexToRGB(renderer.GRAY_12);
      this.body.transform.colorTransform = renderer.hexToRGB(renderer.GRAY_28);
    }

    private function onMouseDown(e:MouseEvent) : void {
      ExternalInterface.call("POST_SOUND_EVENT",CLICK_SOUND);
      this.border.transform.colorTransform = renderer.hexToRGB(renderer.GRAY_9);
      this.body.transform.colorTransform = renderer.hexToRGB(renderer.GRAY_16);
    }

    private function onMouseUp(e:MouseEvent) : void {
      this.border.transform.colorTransform = renderer.hexToRGB(renderer.GRAY_12);
      this.body.transform.colorTransform = renderer.hexToRGB(renderer.GRAY_28);
    }

    private function onClick(e:MouseEvent) : void {
      for each (var listener:Function in this.listeners)
        listener.call();
    }

    public function get text() : String {
      return this._text.text;
    }
  }
}
