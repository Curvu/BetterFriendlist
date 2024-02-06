package {
  import flash.filters.DropShadowFilter;
  import flash.text.TextField;
  import flash.text.TextFormat;

  public class renderer {
    private static const TEXT_SHADOW:DropShadowFilter = new DropShadowFilter(1,45,0,1,0,0,1,1);
    private static const TEXT_FORMAT_DEFAULT:TextFormat = new TextFormat("Open Sans",12,16777215,false);
    private static const TEXT_FORMAT_SMALL:TextFormat = new TextFormat("Open Sans",9,4738417,true,false,false,false,false,"center");

    public static const GREEN:uint = 5299046;
    public static const BLACK:uint = 0;
    public static const WHITE:uint = 16777215;
    public static const GRAY_9:uint = 592137;
    public static const GRAY_12:int = 789516;
    public static const GRAY_16:int = 1052688;
    public static const GRAY_22:int = 1447446;
    public static const GRAY_25:int = 1644825;
    public static const GRAY_28:int = 1842204;
    public static const GRAY_30:int = 1973790;
    public static const GRAY_34:int = 2236962;
    public static const GRAY_38:int = 2500134;
    public static const GRAY_41:int = 2697513;
    public static const GRAY_48:int = 3158064;
    public static const DEFAULT_NAME_COLOR:int = 16250871;
    public static const RANK_COLOR:int = 16768589;
    public static const FAVORITE_COLOR:int = 16201328;
    public static const CLEANER_COLOR:int = 4290479868;
    public static const LEECHER_COLOR:int = 4292997629;

    public function renderer() {
      super();
    }

    public static function rectangle(s:*, x:int = 0, y:int = 0, w:int = 0, h:int = 0, rgb:int = 0, a:Number = 1) : * {
      if(!s) return;
      s.graphics.beginFill(rgb,a);
      s.graphics.drawRect(x,y,w,h);
      s.graphics.endFill();
      return s;
    }

    public static function outline(s:*, x:int = 0, y:int = 0, w:int = 0, h:int = 0, rgb:int = 0, a:Number = 1, t:int = 1) : * {
      if(!s) return;
      s.graphics.beginFill(rgb,a);
      s.graphics.drawRect(x,y,w - t,t);
      s.graphics.drawRect(x + w - t,y,t,h);
      s.graphics.drawRect(x,y + h - t,w - t,t);
      s.graphics.drawRect(x,y + t,t,h - t);
      s.graphics.endFill();
      return s;
    }

    public static function text(x:int = 0, y:int = 0, fmt:* = null, autosize:String = "", shadow:Boolean = false, str:String = "") : TextField {
      var tf:TextField = new TextField();
      if(shadow) tf.filters = [TEXT_SHADOW.clone()];
      if(typeof fmt == "string" && fmt == "-") fmt = TEXT_FORMAT_SMALL;
      else if(!fmt) fmt = TEXT_FORMAT_DEFAULT;

      tf.setTextFormat(fmt);
      tf.defaultTextFormat = fmt;
      if(autosize != "") tf.autoSize = autosize;
      tf.mouseEnabled = false;
      tf.x = x;
      tf.y = y;
      tf.text = str;
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
