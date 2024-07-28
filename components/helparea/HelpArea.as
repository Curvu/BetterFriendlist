package components.helparea {
  import flash.display.Sprite;
  import flash.text.TextField;

  public class HelpArea extends Sprite {
    private var text_area:TextField;

    public function HelpArea(strings:Array, x:int, y:int) {
      super();
      this.visible = false;

      // get the longest string
      var longest:int = 0;
      for each(var str:String in strings)
        if(str.length > longest)
          longest = str.length;

      // create the text area
      renderer.borderRectangle(this, x, y, longest * 4.75, strings.length * 12 + 20, renderer.GRAY_30, renderer.GRAY_12);

      for each(var s:String in strings) {
        text_area = renderer.text(s, x + 5, y + 3, 11, "left", longest * 8, 12);
        addChild(text_area);
        y += 15;
      }
    }
  }
}
