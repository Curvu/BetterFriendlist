package {
  import flash.filters.DropShadowFilter;
  import flash.text.TextField;
  import flash.text.TextFormat;
  import flash.geom.Matrix;
  import flash.display.GradientType;
  import flash.geom.ColorTransform;

  public class renderer {
    private static const TEXT_SHADOW:DropShadowFilter = new DropShadowFilter(1, 45, 0, 1, 0, 0, 1, 1);
    private static const TEXT_FORMAT_DEFAULT:TextFormat = new TextFormat("Open Sans", 12, 0xFFFFFF, false);
    private static const TEXT_FORMAT_SMALL:TextFormat = new TextFormat("Open Sans", 9, 0x484D71, true, false, false, null, null, "center");

    private static const FMT:TextFormat = new TextFormat("Open Sans", null, WHITE, null, false, false, null, null);
    private static const SHADOW:DropShadowFilter = new DropShadowFilter(1, 45, 0, 1, 0, 0, 1, 1);

    public static const WHITE:uint = 0xFFFFFF;
    public static const MASK:uint = 0xFF00FF;

    public static const COLORS:Object = {
      "red": 0xFE014C,
      "orange": 0xF86929,
      "yellow": 0xFFD810,
      "green": 0xADFF00,
      "cyan": 0x00FFFF,
      "blue": 0x0156FF,
      "purple": 0xA839FF
    };

    public function renderer() {
      super();
    }

    public static function font(txt:String, color:String) {
      return "<font color='" + color + "'>" + txt + "</font>";
    }

    public static function hexToRGB(hex:uint):ColorTransform {
      var red:uint = (hex >> 16) & 0xFF;
      var green:uint = (hex >> 8) & 0xFF;
      var blue:uint = hex & 0xFF;

      return new ColorTransform(0, 0, 0, 1, red, green, blue, 0);
    }

    public static function rgbToHex(rgb:uint):String {
      var r:uint = (rgb >> 16) & 0xFF;
      var g:uint = (rgb >> 8) & 0xFF;
      var b:uint = rgb & 0xFF;
      var rh:String = (r < 16 ? "0" : "") + r.toString(16);
      var gh:String = (g < 16 ? "0" : "") + g.toString(16);
      var bh:String = (b < 16 ? "0" : "") + b.toString(16);
      return "#" + rh + gh + bh;
    }

    public static function rectangle(s:*, x:int = 0, y:int = 0, w:int = 0, h:int = 0, rgb:int = 0, a:Number = 1) : * {
      if(!s) return;
      s.graphics.beginFill(rgb,a);
      s.graphics.drawRect(x,y,w,h);
      s.graphics.endFill();
      return s;
    }

    public static function rounded(s:*, x:int = 0, y:int = 0, w:int = 0, h:int = 0, r:int = 0, rgb:int = 0, a:Number = 1) : * {
      if(!s) return;
      s.graphics.beginFill(rgb,a);
      s.graphics.drawRoundRect(x,y,w,h,r);
      s.graphics.endFill();
      return s;
    }

    public static function borderRectangle(s:*, x:int = 0, y:int = 0, w:int = 0, h:int = 0, rgb:int = 0, rgb_border:int = 0) : * {
      if(!s) return;
      s = renderer.rectangle(s, x-1, y-1, w+2, h+2, rgb_border);
      s = renderer.rectangle(s, x, y, w, h, rgb);
      return s;
    }

    public static function text(str:String = "", x:int = 0, y:int = 0, size:Number = 8, align:String = "left", w:int = -1, h:int = -1, wordWrap:Boolean = false, isBold:Boolean = false):TextField {
      var tf:TextField = new TextField();
      tf.filters = [SHADOW];
      FMT.size = size;
      FMT.align = align;
      FMT.bold = isBold;
      tf.defaultTextFormat = FMT;
      tf.mouseEnabled = false;
      tf.x = x;
      tf.y = y;
      tf.htmlText = str;
      if (w != -1) tf.width = w;
      if (h != -1) tf.height = h;
      tf.wordWrap = wordWrap;
      tf.autoSize = align;
      return tf;
    }

    public static function circle(s:*, x:int = 0, y:int = 0, r:Number = 0, rgb:int = 0, a:Number = 1) : * {
      if(!s) return;
      s.graphics.beginFill(rgb, a);
      s.graphics.drawCircle(x, y, r);
      s.graphics.endFill();
      return s;
    }
  }
}
