package components.colorpicker {
  import flash.display.Sprite;
  import flash.events.MouseEvent;

  import ui.*;

  public class Picker extends Sprite {
    private var friends:Friends;
    private var header:Header;

    private var color_btns:Object = {};
    private var _active_color:String;

    public function Picker(friends:Friends, header:Header) {
      super();
      this.friends = friends;
      this.header = header;
      this._active_color = config.cfg.active_color;

      renderer.rounded(this, -1, -1, 18, 146, 10, renderer.GRAY_12);
      renderer.rounded(this, 0, 0, 16, 144, 8, renderer.GRAY_30);
      this.x = 366;

      this.buildColors();
    }

    private function buildColors() : void {
      var idx:int = 0;
      var btn:ColorButton = null;
      for each (var clr:String in config.colors) {
        btn = new ColorButton(5, clr, 8, 8 + idx * 18);
        if (this._active_color == clr) {
          btn.toggled = true;
          idx++;
        }
        btn.addEventListener(MouseEvent.CLICK, this.onColorChange);
        btn.addEventListener(MouseEvent.RIGHT_CLICK, this.onInviteColor);
        this.color_btns[clr] = btn;
        this.addChild(this.color_btns[clr]);
        idx++;
      }
    }

    private function onColorChange(e:MouseEvent) : void {
      this.active_color = e.target.color;
    }

    private function onInviteColor(e:MouseEvent) : void {
      this.friends.inviteColor(e.target.color);
    }

    public function get active_color() : String {
      return this._active_color;
    }

    public function set active_color(clr:String) : void {
      if (this._active_color == clr) return;
      this.color_btns[this._active_color].toggled = false;
      this._active_color = clr;
      this.color_btns[this._active_color].toggled = true;

      for each(var btn:ColorButton in this.color_btns) {
        btn.removeEventListener(MouseEvent.CLICK, this.onColorChange);
        btn.removeEventListener(MouseEvent.RIGHT_CLICK, this.onInviteColor);
        this.removeChild(btn);
      }

      this.buildColors();

      config.cfg.active_color = clr;
      config.configWrite("active_color");
      this.friends.updateQL();
      this.header.updateField();
    }
  }
}
