package components.keyboard {
  import flash.display.Sprite;
  import flash.display.Shape;
  import flash.events.MouseEvent;
  import flash.text.TextField;

  public class Keyboard extends Sprite {
    private var friends:Friends;

    private var characters:String = "1234567890QWERTYUIOPASDFGHJKL_ZXCVBNM"

    private var inputContainer:Shape;
    private var inputField:TextField;
    private var _input:String = "";

    public function Keyboard(x:int, y:int, friends:Friends) {
      super();
      this.friends = friends;

      renderer.borderRectangle(this, x, y, 200, 102, renderer.GRAY_30, renderer.GRAY_12);
      this.visible = false;

      var key:Key;
      for (var i:int = 0; i < this.characters.length; i++) {
        key = new Key(16, 16, this.characters.charAt(i), 0, 0);
        key.x = i % 10 * 20 + x + 2;
        key.y = (int(i / 10)+1) * 20 + 4;
        key.addEventListener(MouseEvent.CLICK, this.onClickKey);
        this.addChild(key);
      }

      // CE - clear entry
      key = new Key(26, 16, "CE", 0, 0);
      key.x = 7 * 20 + x + 2;
      key.y = 4 * 20 + 4;
      key.addEventListener(MouseEvent.CLICK, this.clearEntry);
      this.addChild(key);

      // AC - all clear
      key = new Key(26, 16, "AC", 0, 0);
      key.x = 8 * 20 + x + 12;
      key.y = 4 * 20 + 4;
      key.addEventListener(MouseEvent.CLICK, this.clearAll);
      this.addChild(key);

      // input field
      this.inputContainer = renderer.rectangle(new Shape(), x + 2, y + 2, 196, 19, renderer.GRAY_34);
      this.inputField = renderer.text("", x + 3, y, 12, "left", 195, 18);
      this.addChild(this.inputContainer);
      this.addChild(this.inputField);
      this.addEventListener(MouseEvent.RIGHT_CLICK, this.toggle);
    }

    // event handlers
    private function onClickKey(e:MouseEvent):void {
      var key:Key = e.currentTarget as Key;
      if (this.input.length >= 20) return;
      this.input += key.text;
    }

    private function clearEntry(e:MouseEvent):void {
      this.input = this.input.substr(0, this.input.length - 1);
    }

    private function clearAll(e:MouseEvent):void {
      this.input = "";
    }

    // getters and setters
    public function get input():String {
      return this._input;
    }

    public function set input(value:String):void {
      this._input = value;
      this.inputField.text = value;
      this.friends.search(value);
    }

    // helpers
    public function toggle(e:MouseEvent=null):void {
      this.visible = !this.visible;
    }

    public function clear():void {
      this._input = "";
      this.inputField.text = "";
    }
  }
}
