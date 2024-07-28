package {
  import flash.external.ExternalInterface;
  import flash.text.TextField;
  import flash.display.MovieClip;

  public class Broadcast extends MovieClip {
    public var debugline:TextField;
    private var friends:Friends;

    public function Broadcast() {
      super();
      ExternalInterface.addCallback("loadModConfiguration", this.onLoadModConfiguration);
      config.M = this;
      this.debugline.x = 400;
      this.debugline.text = "";
      this.friends = new Friends();
      addChild(this.friends.full_list);
      ExternalInterface.addCallback("clear", this.onClear);
      ExternalInterface.addCallback("addFriend", this.addFriend);
      ExternalInterface.addCallback("addIgnored", this.addIgnored);
      ExternalInterface.addCallback("updateFriend", this.updateFriend);
      ExternalInterface.addCallback("removeFriend", this.removeFriend);
    }

    public function onLoadModConfiguration(key:String, val:String) : void {
      config.onLoadModConfig(key,val);
      if(key == "betterfriendlist:default-tab") {
        this.friends.tab = int(Number(val));
      } else if(key == "betterfriendlist:vertical-offset") {
        this.friends.applyOffset(int(Number(val)));
      } else if(key == "betterfriendlist:max-rows") {
        this.friends.onSortTimerComplete();
      }
    }

    public function set msg(str:String) : void {
      var lines:Array = this.debugline.text.split("\n");
      while(lines.length > 30) lines.shift();
      this.debugline.text = lines.join("\n") + "\n" + str;
    }

    public function get msg() : String {
      return this.debugline.text;
    }

    private function onClear() : void {
      this.friends.clear();
    }

    private function addFriend(uid:String, name:String, isOnline:Boolean, world:String, rank:String, canJoin:Boolean, isRequest:Boolean, canAccept:Boolean, canInvite:Boolean, teamPvpEnabled:Boolean) : void {
      this.friends.add(uid, name, isOnline, world, rank, canJoin, isRequest, canAccept, canInvite);
    }

    private function addIgnored(uid:String, name:String) : void {
      this.friends.add(uid,name,false,"","",false,false,false,false,true);
    }

    private function updateFriend(uid:String, name:String, isOnline:Boolean, world:String, rank:String, canJoin:Boolean, isRequest:Boolean, canAccept:Boolean, canInvite:Boolean, teamPvpEnabled:Boolean) : void {
      this.friends.update(uid,name,isOnline,world,rank,canJoin,isRequest,canAccept,canInvite,false);
    }

    private function removeFriend(uid:String) : void {
      this.friends.remove(uid);
    }
  }
}
