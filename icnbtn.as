package {
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.geom.ColorTransform;

  public class icnbtn extends Sprite {
    public static const COLOR_IDLE:ColorTransform = new ColorTransform(1,1,1,0.2,129,143,178);

    public static const COLOR_HOVER:ColorTransform = new ColorTransform(1,1,1,0.5,129,143,178);

    public static const COLOR_ACTIVE:ColorTransform = new ColorTransform(1,1,1,0.5,80,91,119);

    public static const COLOR_DISABLED:ColorTransform = new ColorTransform(1,1,1,0.75,15,15,27);

    public static const COLOR_WHITE:ColorTransform = new ColorTransform(1,1,1,1,255,255,255);

    public static const CLICK_SOUND:String = "Play_ui_button_select";

    private var _toggled:Boolean = false;

    private var _disabled:Boolean = false;

    private var toggled_color:ColorTransform;
    private var idle_color:ColorTransform;
    private var hover_color:ColorTransform;
    private var active_color:ColorTransform;

    private static const colors:Object = {
      red: {
        max: new ColorTransform(1, 0, 0, 1, 254, 1, 76),
        medium: new ColorTransform(1, 0, 0, 0.5, 254, 1, 76),
        semi: new ColorTransform(1, 0, 0, 0.4, 254, 1, 76),
        min: new ColorTransform(1, 0, 0, 0.2, 254, 1, 76)
      },
      orange: {
        max: new ColorTransform(1, 0.5, 0, 1, 248, 105, 41),
        medium: new ColorTransform(1, 0.5, 0, 0.5, 248, 105, 41),
        semi: new ColorTransform(1, 0.5, 0, 0.4, 248, 105, 41),
        min: new ColorTransform(1, 0.5, 0, 0.2, 248, 105, 41)
      },
      yellow: {
        max: new ColorTransform(1, 1, 0, 1, 255, 216, 16),
        medium: new ColorTransform(1, 1, 0, 0.5, 255, 216, 16),
        semi: new ColorTransform(1, 1, 0, 0.4, 255, 216, 16),
        min: new ColorTransform(1, 1, 0, 0.2, 255, 216, 16)
      },
      green: {
        max: new ColorTransform(0, 1, 0, 1, 173, 255, 0),
        medium: new ColorTransform(0, 1, 0, 0.5, 173, 255, 0),
        semi: new ColorTransform(0, 1, 0, 0.4, 173, 255, 0),
        min: new ColorTransform(0, 1, 0, 0.2, 173, 255, 0)
      },
      cyan: {
        max: new ColorTransform(0, 1, 1, 1, 0, 255, 255),
        medium: new ColorTransform(0, 1, 1, 0.5, 0, 255, 255),
        semi: new ColorTransform(0, 1, 1, 0.4, 0, 255, 255),
        min: new ColorTransform(0, 1, 1, 0.2, 0, 255, 255)
      },
      blue: {
        max: new ColorTransform(0, 0, 1, 1, 1, 86, 255),
        medium: new ColorTransform(0, 0, 1, 0.5, 1, 86, 255),
        semi: new ColorTransform(0, 0, 1, 0.4, 1, 86, 255),
        min: new ColorTransform(0, 0, 1, 0.2, 1, 86, 255)
      },
      purple: {
        max: new ColorTransform(0.5, 0, 1, 1, 168, 57, 255),
        medium: new ColorTransform(0.5, 0, 1, 0.5, 168, 57, 255),
        semi: new ColorTransform(0.5, 0, 1, 0.4, 168, 57, 255),
        min: new ColorTransform(0.5, 0, 1, 0.2, 168, 57, 255)
      }
    };

    public function icnbtn(icon:*, w:int = 24, h:int = 24, bool:Boolean = false) {
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

      this.idle_color = COLOR_IDLE;
      this.toggled_color = COLOR_WHITE;
      this.hover_color = COLOR_HOVER;
      this.active_color = COLOR_ACTIVE;
      if (bool) {
        this.idle_color = colors[config.cfg.active_color]["min"];
        this.hover_color = colors[config.cfg.active_color]["medium"];
        this.toggled_color = colors[config.cfg.active_color]["max"];
        this.active_color = colors[config.cfg.active_color]["semi"];
      }

      this.addMouseEventListeners();
      this.transform.colorTransform = this.idle_color;
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
          this.transform.colorTransform = this.idle_color;
        }
      }
    }

    public function get toggled() : Boolean {
      return this._toggled;
    }

    public function set toggled(toggled:Boolean) : void {
      this.transform.colorTransform = toggled ? this.toggled_color : this.idle_color;
      this._toggled = toggled;
    }

    public function updateColor() : void {
      this.idle_color = colors[config.cfg.active_color]["min"];
      this.hover_color = colors[config.cfg.active_color]["medium"];
      this.toggled_color = colors[config.cfg.active_color]["max"];
      this.active_color = colors[config.cfg.active_color]["semi"];

      this.transform.colorTransform = this.toggled ? this.toggled_color : this.idle_color;
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
      if(!this.toggled) this.transform.colorTransform = this.hover_color;
    }

    private function onMouseOut() : void {
      if(!this.toggled) this.transform.colorTransform = this.idle_color;
    }

    private function onMouseDown() : void {
      ExternalInterface.call("POST_SOUND_EVENT", CLICK_SOUND);
      this.transform.colorTransform = this.active_color;
    }

    private function onMouseUp() : void {
      this.transform.colorTransform = !this.toggled ? this.hover_color : this.toggled_color;
    }
  }
}
