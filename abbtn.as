package {
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.geom.ColorTransform;

  public class abbtn extends Sprite {
    public static const ENV:Boolean = abi.DEBUG > 2;

    public static const COLOR_IDLE:ColorTransform = new ColorTransform(1,1,1,0.2,129,143,178);

    public static const COLOR_HOVER:ColorTransform = new ColorTransform(1,1,1,0.5,129,143,178);

    public static const COLOR_ACTIVE:ColorTransform = new ColorTransform(1,1,1,0.5,80,91,119);

    public static const COLOR_DISABLED:ColorTransform = new ColorTransform(1,1,1,0.75,15,15,27);

    public static const COLOR_WHITE:ColorTransform = new ColorTransform(1,1,1,1,255,255,255);

    public static const CLICK_SOUND:String = "Play_ui_button_select";

    private var _toggled:Boolean = false;

    private var _disabled:Boolean = false;

    public function abbtn(icon:*, w:int = 24, h:int = 24) {
      super();
      renderer.rectangle(this,0,0,w,h,0,0);
      if(icon) {
        this.addChild(icon);
        if(icon.width < w) {
          icon.x = int(w / 2 - icon.width / 2 + 0.5);
        }

        if(icon.height < h) {
          icon.y = int(h / 2 - icon.height / 2 + 0.5);
        }
      }
      this.addMouseEventListeners();
      this.transform.colorTransform = COLOR_IDLE;
      if(ENV) renderer.outline(this,0,0,w,h,16711935,1);
    }

    public function get disabled() : Boolean {
      return this._disabled;
    }

    public function set disabled(b:Boolean) : void {
      if(this._disabled != b) {
        this._disabled = b;
        if(b) {
          this.removeMouseEventListeners();
          this.transform.colorTransform = COLOR_DISABLED;
        } else {
          this.addMouseEventListeners();
          this.transform.colorTransform = COLOR_IDLE;
        }
      }
    }

    public function get toggled() : Boolean {
      return this._toggled;
    }

    public function set toggled(toggled:Boolean) : void {
      this.transform.colorTransform = toggled ? COLOR_WHITE : COLOR_IDLE;
      this._toggled = toggled;
    }

    private function addMouseEventListeners() : void {
      this.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
      this.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      this.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
      this.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
    }

    private function removeMouseEventListeners() : void {
      this.removeEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
      this.removeEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
      this.removeEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
      this.removeEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
    }

    private function onMouseOver() : void {
      if(!this.toggled) this.transform.colorTransform = COLOR_HOVER;
    }

    private function onMouseOut() : void {
      if(!this.toggled) this.transform.colorTransform = COLOR_IDLE;
    }

    private function onMouseDown() : void {
      ExternalInterface.call("POST_SOUND_EVENT", CLICK_SOUND);
      this.transform.colorTransform = COLOR_ACTIVE;
    }

    private function onMouseUp() : void {
      this.transform.colorTransform = !this.toggled ? COLOR_HOVER : COLOR_WHITE;
    }
  }
}
