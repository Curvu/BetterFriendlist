package
{
   import flash.display.*;
   import flash.geom.*;
   
   public class IggyFunctions
   {
      
      public static var inIggy:* = false;
      
      public static const HITTEST_NO_MOUSE:int = 1;
      
      public static const HITTEST_NO_GET_OBJECTS_UNDER_POINT:int = 2;
      
      public static const HITTEST_NO_IGGY_GET_OBJECTS_UNDER_POINT:int = 4;
       
      
      public function IggyFunctions()
      {
         super();
      }
      
      public static function translate(param1:String) : *
      {
         return param1;
      }
      
      public static function setTextureForBitmap(param1:Bitmap, param2:Object, param3:int = -1, param4:int = -1) : *
      {
         if(!(param2 is String))
         {
            if(param2 != null)
            {
               throw new TypeError("must be String or null");
            }
         }
      }
      
      public static function iggyGetObjectsUnderPoint(param1:DisplayObjectContainer, param2:Point) : Array
      {
         return param1.getObjectsUnderPoint(param2);
      }
      
      public static function setHittestProperties(param1:InteractiveObject, param2:int) : *
      {
      }
      
      public static function getHittestProperties(param1:InteractiveObject) : *
      {
         return 0;
      }
      
      public static function setObjectAntialiasingEnable(param1:DisplayObject, param2:Boolean) : *
      {
      }
      
      public static function setDepth(param1:DisplayObject, param2:Number) : *
      {
         param1["_iggy_depth"] = param2;
      }
      
      public static function getDepth(param1:DisplayObject) : *
      {
         if("_iggy_depth" in param1)
         {
            return param1["_iggy_depth"];
         }
         return 0;
      }
   }
}
