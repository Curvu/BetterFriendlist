package ui {
  import flash.display.Sprite;
  import flash.text.TextField;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;

  import components.buttons.*;
  import components.keyboard.Keyboard;
  import components.helparea.*;
  import components.colorpicker.Picker;

  public class Header extends Sprite {
    private var friends:Friends;

    private var main:Sprite;
    private var items:Sprite;

    private var _width:int;

    private var _field:TextField;
    private var _count:int = 0;
    private var _online:int = 0;

    private var _requests:TextField;

    public var tab_buttons:Array = [];
    private var header_items:Array = [];

    private var keyboard:Keyboard;
    private var help_all:HelpArea;
    private var help_quick:HelpArea;
    private var picker:Picker;

    public function Header(friends:Friends) {
      super();
      this.friends = friends;

      this._width = 364;
      this.main = renderer.rectangle(new Sprite(), 0, -1, _width, 45, renderer.GRAY_22, 1);
      this.items = renderer.rectangle(new Sprite(), 0, 29, _width, 15, renderer.GRAY_16, 1);
      this.y = -43;
      this.addChild(this.main);
      this.addChild(this.items);

      this._field = renderer.text("", 307, 4, 11, "right", 50, 12);
      this.main.addChild(this._field);

      this.buildTabButtons();
      this.buildHeaderItems();

      this._requests = renderer.text("", 121, -1, 10, "left", 0, 0, false, true);
      this._requests.textColor = renderer.FAVORITE_COLOR;
      this.main.addChild(this._requests);

      this.picker = new Picker(this.friends, this);
      this.main.addChild(this.picker);
    }

    private function buildTabButtons() : void {
      this.tab_buttons = [
        new icnbtn(config.scale(new IconFriends(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconHeart(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconQuickList(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconRequest(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconIgnore(), 0.75), 24, 24)
      ];

      for (var i:int = 0; i < this.tab_buttons.length; i++) {
        this.tab_buttons[i].x = i * 32 + 10;
        this.tab_buttons[i].y = 3;
        this.tab_buttons[i].name = String(i);
        this.tab_buttons[i].addEventListener(MouseEvent.CLICK, this.onTabClicked);
        this.main.addChild(this.tab_buttons[i]);
      }
    }

    private function buildHeaderItems() : void {
      var items:Array = [
        new Button(125, 13, "ADD FRIEND", 1, 30),
        new Button(60, 13, "SEARCH", 127, 30),
        new Button(14, 13, "?", 188, 30, true),
        renderer.text("INVITE", 268, 28, 9),
        renderer.text("JOIN", 316, 28, 9)
      ];
      this.header_items[config.TAB_ALL] = items;

      items = [
        renderer.text("FAVORITES", 1, 28, 9),
        renderer.text("INVITE", 268, 28, 9),
        renderer.text("JOIN", 316, 28, 9)
      ]
      this.header_items[config.TAB_FAV] = items;

      items = [
        renderer.text("QUICK LIST", 1, 28, 9),
        new Button(14, 13, "?", 240, 30, true),
        new Button(14, 13, "X", 255, 30),
        new Button(93, 13, "INVITE ALL", 270, 30)
      ]
      this.header_items[config.TAB_QUICK] = items;

      items = [
        renderer.text("FRIEND REQUESTS", 1, 28, 9),
        new Button(93, 13, "ACCEPT ALL", 270, 30)
      ];
      this.header_items[config.TAB_REQUEST] = items;

      items = [
        renderer.text("IGNORED PLAYERS", 1, 28, 9),
        new Button(93, 13, "ADD IGNORED", 270, 30)
      ]
      this.header_items[config.TAB_IGNORED] = items;

      this.header_items[config.TAB_ALL][0].addEventListener(MouseEvent.CLICK, this.onAdd);
      this.header_items[config.TAB_ALL][1].addEventListener(MouseEvent.CLICK, this.onSearch);
      this.header_items[config.TAB_ALL][2].addEventListener(MouseEvent.MOUSE_OVER, this.onHelpMouseOverAll);
      this.header_items[config.TAB_ALL][2].addEventListener(MouseEvent.MOUSE_OUT, this.onHelpMouseOut);

      this.header_items[config.TAB_QUICK][1].addEventListener(MouseEvent.MOUSE_OVER, this.onHelpMouseOverQuick);
      this.header_items[config.TAB_QUICK][1].addEventListener(MouseEvent.MOUSE_OUT, this.onHelpMouseOut);
      this.header_items[config.TAB_QUICK][2].addEventListener(MouseEvent.CLICK, this.onClearQuickList);
      this.header_items[config.TAB_QUICK][3].addEventListener(MouseEvent.CLICK, this.inviteAll);

      this.header_items[config.TAB_REQUEST][1].addEventListener(MouseEvent.CLICK, this.onAcceptAll);

      this.header_items[config.TAB_IGNORED][1].addEventListener(MouseEvent.CLICK, this.onAdd);

      this.updateHeaderItems();
    }

    /*--- Events ---*/

    private function onTabClicked(e:MouseEvent) : void {
      var btn:icnbtn = e.currentTarget as icnbtn;
      if (!btn) return;
      const tab:int = int(btn.name);
      if (tab == this.friends.tab) return;

      const last:int = this.friends.tab;
      this.friends.tab = tab;

      if (last == config.TAB_IGNORED && tab != last)
        ExternalInterface.call("OnTabClick", 0);
      else if (last != config.TAB_IGNORED && tab == config.TAB_IGNORED && tab != last)
        ExternalInterface.call("OnTabClick", 1);

      this.update();
    }

    private function onAdd(e:MouseEvent) : void {
      ExternalInterface.call("OnInvite");
    }

    private function onSearch(e:MouseEvent) : void {
      if(!this.keyboard) {
        this.keyboard = new Keyboard(385, 0, this.friends);
        this.main.addChild(this.keyboard);
      }
      this.keyboard.toggle();
    }

    private function onHelpMouseOverAll(e:MouseEvent) : void {
      if(!this.help_all) {
        this.help_all = new HelpArea(["<b>LEFT-CLICK</b> player to Whisper", "<b>RIGHT-CLICK</b> player to remove him", "<b>RIGHT-CLICK</b> player color to remove it", "<b>RIGHT-CLICK</b> Keyboard to close it"], 366, 0);
        this.main.addChild(this.help_all);
      }
      this.help_all.visible = true;
    }

    private function onHelpMouseOverQuick(e:MouseEvent) : void {
      if(!this.help_quick) {
        this.help_quick = new HelpArea(["<b>LEFT-CLICK</b> color to go to that list", "<b>RIGHT-CLICK</b> color to invite everyone on that list"], 366, 0);
        this.main.addChild(this.help_quick);
      }
      this.help_quick.visible = true;
    }

    private function onHelpMouseOut(e:MouseEvent) : void {
      if(this.help_all) this.help_all.visible = false;
      if(this.help_quick) this.help_quick.visible = false;
    }

    private function onClearQuickList(e:MouseEvent) : void {
      var color:String = config.cfg.active_color;
      config[color] = {};
      config.configWrite(color);

      for each (var f:Friend in this.friends.list_colors[color])
        f.refreshColors();

      this.friends.list_colors[color].length = 0;
      this.friends.onSortTimerComplete();
      this.updateField();
    }

    private function onAcceptAll(e:MouseEvent) : void {
      var idx:int = int(this.friends.list_request.length);
      while(idx--) {
        if(this.friends.list_request[idx].can_accept) {
          this.friends.list_request[idx].onAccept(null);
          this.friends.list_request.splice(idx, 1);
        }
      }
    }

    private function inviteAll(e:MouseEvent) : void {
      for each (var color:String in config.colors)
        this.friends.inviteColor(color);
    }

    // Others
    public function update() : void {
      this.updateHeaderItems();
      this.updateField();
      this.friends.updateQL();

      if (this.friends.tab != config.TAB_ALL && this.keyboard) {
        this.keyboard.visible = false;
        this.keyboard.clear();
      }

      this.picker.visible = this.friends.tab == config.TAB_QUICK || this.friends.tab == config.TAB_ALL;
    }

    public function updateHeaderItems() : void {
      while (this.items.numChildren > 0)
        this.items.removeChildAt(0);

      for each (var item:* in this.header_items[this.friends.tab])
        this.items.addChild(item);
    }

    public function updateField():void {
      if (this.friends.tab == config.TAB_ALL) {
        this._field.htmlText = "<b>"+renderer.font(this._online.toString(), "#50DB66")+"</b>"+renderer.font("/"+(this._count).toString(), "#CECED7");
      } else if (this.friends.tab == config.TAB_QUICK) {
        this._field.htmlText = "<b>"+renderer.font(this.friends.list_colors[config.cfg.active_color].length.toString(), "#CECED7")+"</b>";
      } else this._field.htmlText = "";
    }

    public function clear() : void {
      this.requests = 0;
      this.count = 0;
      this.online = 0;
      this.header_items[config.TAB_REQUEST][1].count = 0;
    }

    // Getters and Setters
    public function get searched() : String {
      return this.keyboard ? this.keyboard.input : "";
    }

    override public function get width():Number {
      return this._width;
    }

    public function get count():uint {
      return this._count;
    }

    public function get online():uint {
      return this._online;
    }

    public function set count(value:uint):void {
      this._count = value;
      this.updateField();
    }

    public function set online(value:uint):void {
      this._online = value;
      this.updateField();
    }

    public function get requests() : Number {
      return this._requests.text != "" ? Number(this._requests.text) : 0;
    }

    public function set requests(num:Number) : void {
      this._requests.text = num != 0 ? num.toString() : "";
      this.header_items[config.TAB_REQUEST][1].count = num;
      this.picker.active_color = config.cfg.active_color;
    }
  }
}
