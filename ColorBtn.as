package {
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.geom.ColorTransform;
  import flash.text.TextField;
  import flash.text.TextFormat;

  public class ColorBtn extends Sprite {
    public static const CLICK_SOUND:String = "Play_ui_button_select";
    private var bg:Shape;
    private var listeners:Array = [];

    private var _toggled:Boolean = false;

    private var radius:int;
    public var color:String;

    public function ColorBtn(r:int = 5, clr:String = "red", x:int = 0, y:int = 0) {
      super();
      this.radius = r;
      this.color = clr;

      // make the button clickable in a rectangular area
      renderer.rectangle(this, -r*2, -r*2, r*4, r*4, 0, 0, 0);

      this.bg = renderer.circle(new Shape(), -0.5, -0.5, r, renderer.GRAY_16, 1);
      this.bg = renderer.circle(this.bg, 0, 0, r-1, renderer.COLORS[clr], 1);

      this.addChild(this.bg);

      this.addMouseEventListeners();

      this.x = x;
      this.y = y;
    }

    public function get toggled() : Boolean {
      return this._toggled;
    }

    public function set toggled(toggled:Boolean) : void {
      this._toggled = toggled;

      this.bg.graphics.clear();

      if (this._toggled) {
        renderer.rounded(this.bg, -this.radius, -this.radius, 30, this.radius*2, 10, renderer.WHITE, 1);
        renderer.rounded(this.bg, -this.radius+1, -this.radius+1, 30-2, this.radius*2-2, 10, renderer.COLORS[this.color], 1);
      } else {
        renderer.circle(this.bg, -0.5, -0.5, this.radius, renderer.GRAY_16, 1);
        renderer.circle(this.bg, 0, 0, this.radius-1, renderer.COLORS[this.color], 1);
      }
    }

    private function addMouseEventListeners() : void {
      this.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
      this.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      this.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
      this.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
      this.addEventListener(MouseEvent.CLICK,this.onClick);
    }

    private function onMouseOver() : void {
      if (this._toggled) return;
      this.bg.graphics.clear();
      renderer.circle(this.bg, -0.5, -0.5, this.radius, renderer.WHITE, 1);
      renderer.circle(this.bg, 0, 0, this.radius-1, renderer.COLORS[this.color], 1);
    }

    private function onMouseOut() : void {
      if (this._toggled) return;
      this.bg.graphics.clear();
      renderer.circle(this.bg, -0.5, -0.5, this.radius, renderer.GRAY_16, 1);
      renderer.circle(this.bg, 0, 0, this.radius-1, renderer.COLORS[this.color], 1);
    }

    private function onMouseDown() : void {
      ExternalInterface.call("POST_SOUND_EVENT", CLICK_SOUND);
      if (this._toggled) return;
      this.bg.graphics.clear();
      renderer.circle(this.bg, -0.5, -0.5, this.radius, renderer.WHITE, 1);
      renderer.circle(this.bg, 0, 0, this.radius-1, renderer.COLORS[this.color], 1);
    }

    private function onMouseUp() : void {
      if (this._toggled) return;
      this.bg.graphics.clear();
      renderer.circle(this.bg, -0.5, -0.5, this.radius, renderer.GRAY_16, 1);
      renderer.circle(this.bg, 0, 0, this.radius-1, renderer.COLORS[this.color], 1);
    }

    private function onClick() : void {
      var idx:int = 0;
      var len:int = int(this.listeners.length);
      while(idx < len) {
        this.listeners[idx].call();
        idx++;
      }
    }
  }
}
