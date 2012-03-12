package com.zwopple.zwoptex {
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;
	
	import mx.collections.*;
	import mx.controls.*;
	import mx.events.*;
	
	import nl.demonsters.debugger.*;

	public class Main extends MovieClip {
		
		public static var debugger:MonsterDebugger;
		
		public var menuBar:MenuBar;
		
		public static const ACTION_LOAD_PROJECT:int = 0;
		public static const ACTION_SAVE_PROJECT:int = 1;
		public static const ACTION_IMPORT_IMAGES:int = 2;
		public static const ACTION_EXPORT_TEXTURE:int = 3;
		public static const ACTION_EXPORT_COORDINATES:int = 4;
		public static const ACTION_SELECT_ALL:int = 5;
		public static const ACTION_TRIM_SELECTED_IMAGES:int = 6;
		public static const ACTION_UNTRIM_SELECTED_IMAGES:int = 7;
		public static const ACTION_CANVAS_WIDTH:int = 8;
		public static const ACTION_CANVAS_HEIGHT:int = 9;
		public static const ACTION_ARRANGE_BY_NAME_WIDTH:int = 10;
		public static const ACTION_ARRANGE_BY_NAME_HEIGHT:int = 11;
		public static const ACTION_ARRANGE_BY_WIDTH:int = 12;
		public static const ACTION_ARRANGE_BY_HEIGHT:int = 13;
		public static const ACTION_ARRANGE_BY_COMPLEX_WIDTH:int = 14;
		public static const ACTION_ARRANGE_BY_COMPLEX_HEIGHT:int = 15;
		public static const ACTION_ARRANGE_MIN_SPACING:int = 16;
		public static const ACTION_DELETE:int = 17;
		
		private var _menuBarXML:XMLList =
			<>
			<menuitem label="File">
			<menuitem label="Load Project" data="0" />
			<menuitem label="Save Project" data="1" />
			<menuitem type="separator" />
			<menuitem label="Import Images" data="2" />
			<menuitem type="separator" />
			<menuitem label="Export Texture" data="3" />
			<menuitem label="Export Coordinates" data="4" />
			</menuitem>
			<menuitem label="Edit">
			<menuitem label="Delete" data="17" />
			<menuitem label="Select All" data="5" />
			</menuitem>
			<menuitem label="Modify">
			<menuitem label="Trim Selected Images" data="6" />
			<menuitem label="Untrim Selected Images" data="7" />
			<menuitem type="separator"/>
			<menuitem label="Canvas Width">
			<menuitem label="64px" data="8" />
			<menuitem label="128px" data="8" />
			<menuitem label="256px" data="8" />
			<menuitem label="512px" data="8" />
			<menuitem label="1024px" data="8" />
			</menuitem>
			<menuitem label="Canvas Height">
			<menuitem label="64px" data="9" />
			<menuitem label="128px" data="9" />
			<menuitem label="256px" data="9" />
			<menuitem label="512px" data="9" />
			<menuitem label="1024px" data="9" />
			</menuitem>
			</menuitem>
			<menuitem label="Arrange">
			<menuitem label="By Name & Width" data="10" />
			<menuitem label="By Name & Height" data="11" />
			<menuitem label="By Width" data="12" />
			<menuitem label="By Height" data="13" />
			<menuitem label="Complex By Width (no spacing)" data="14" />
			<menuitem label="Complex By Height (no spacing)" data="15" />
			<menuitem label="Minimum Spacing">
			<menuitem label="1px" data="16" />
			<menuitem label="2px" data="16" />
			<menuitem label="3px" data="16" />
			<menuitem label="4px" data="16" />
			<menuitem label="5px" data="16" />
			</menuitem>
			</menuitem>
			</>
		
		private var _action:int;
		private var _fileReference:FileReference;
		private var _fileReferenceList:FileReferenceList;
		
		private var _fileList:Array;
		private var _fileListLoadIndex:int = 0;
		
		private var _project:ZTProject;
		private var _arrangeByNameWidthAscending:Boolean = true;
		private var _arrangeByNameHeightAscending:Boolean = true;
		private var _arrangeByWidthAscending:Boolean = true;
		private var _arrangeByHeightAscending:Boolean = true;
		private var _arrangeByWidthComplexAscending:Boolean = true;
		private var _arrangeByHeightComplexAscending:Boolean = true;
		private var _activeMenus:Dictionary;
			
		public function Main(pMenuBar:MenuBar) {
			
			// demonsterdebugger
			//Main.debugger = new MonsterDebugger(this);
			
			// position
			x = 0.0;
			y = 22.0;
			
			// background
			var s:Sprite = new Sprite();
			s.graphics.beginFill(0x333333,1.0);
			s.graphics.drawRect(0.0,0.0,1024.0,1024.0);
			s.graphics.endFill();
			s.name = "canvas";
			addChild(s);
			
			// project
			_project = new ZTProject();
			
			// add canvas
			addChild(_project.canvas);
			
			// add selector
			addChild(_project.selector);
			
			// setup menu bar
			_activeMenus = new Dictionary();
			menuBar = pMenuBar;
			menuBar.dataProvider = new XMLListCollection(_menuBarXML);
			menuBar.addEventListener(MenuEvent.MENU_SHOW, menuShowEvent);
			menuBar.addEventListener(MenuEvent.MENU_HIDE, menuHideEvent);
			menuBar.addEventListener(MenuEvent.ITEM_CLICK, menuItemClickEvent);
		}
		
		protected function menuShowEvent(pEvent:MenuEvent):void {
			_activeMenus[pEvent.menu] = true;
			//_project.selector.removeListeners();
		}
		protected function menuHideEvent(pEvent:MenuEvent):void {
			delete _activeMenus[pEvent.menu];
			var activeMenus:int = 0;
			for(var obj:* in _activeMenus) {
				activeMenus++;
			}
			if(activeMenus <= 0) {
				//_project.selector.addListeners();
			}
		}
		protected function menuItemClickEvent(pEvent:MenuEvent):void {
			var n:Number;
			var data:String = String(pEvent.item.@data);
			var label:String = String(pEvent.item.@label);
			_action = int(data);
			switch(_action) {
				case ACTION_LOAD_PROJECT :
					createFileReference();
					_fileReference.browse([new FileFilter("Zwoptex Project:","*.ztap;*.ztp;")]);
					break;
				case ACTION_SAVE_PROJECT :
					createFileReference();
					_fileReference.save(_project.data, _project.name);
					break;
				case ACTION_IMPORT_IMAGES :
					createFileReferenceList();
					_fileReferenceList.browse([new FileFilter("Images:", "*.jpg;*.jpeg;*.png;*.gif")]);
					break;
				case ACTION_EXPORT_TEXTURE :
					createFileReference();
					_fileReference.save(_project.serializeCanvasToPNG(), _project.savedTextureName);
					break;
				case ACTION_EXPORT_COORDINATES :
					createFileReference();
					_fileReference.save(_project.serializeToPropertyListString(), _project.savedCoordinatesName);
					break;
				case ACTION_DELETE :
					var deleteImages:Array = _project.selector.selectedImages.slice();
					while(deleteImages.length > 1) {
						_project.deleteImage(deleteImages.pop(),false);
					}
					_project.deleteImage(deleteImages.pop(),true);
				case ACTION_SELECT_ALL :
					_project.selectAllImages();
					break;
				case ACTION_TRIM_SELECTED_IMAGES :
					_project.trimImages(_project.selector.selectedImages);
					break;
				case ACTION_UNTRIM_SELECTED_IMAGES :
					_project.untrimImages(_project.selector.selectedImages);
					break;
				case ACTION_CANVAS_WIDTH :
				case ACTION_CANVAS_HEIGHT :
					n = 64.0;
					switch(label) {
						case "64px" :
							n = 64.0;
							break;
						case "128px" :
							n = 128.0;
							break;
						case "256px" :
							n = 256.0;
							break;
						case "512px" :
							n = 512.0;
							break;
						case "1024px" :
							n = 1024.0;
							break;
					}
					switch(_action) {
						case ACTION_CANVAS_WIDTH :
							_project.canvas.width = n;
							_project.repositionImagesInsideCanvas();
							break;
						case ACTION_CANVAS_HEIGHT :
							_project.canvas.height = n;
							_project.repositionImagesInsideCanvas();
							break;
					}
					break;
				case ACTION_ARRANGE_BY_NAME_WIDTH :
					_arrangeByNameWidthAscending = !_arrangeByNameWidthAscending;
					_project.arrangeImagesByNameAndWidth(_arrangeByNameWidthAscending);
					break;
				case ACTION_ARRANGE_BY_NAME_HEIGHT :
					_arrangeByNameHeightAscending = !_arrangeByNameHeightAscending;
					_project.arrangeImagesByNameAndHeight(_arrangeByNameHeightAscending);
					break;
				case ACTION_ARRANGE_BY_WIDTH :
					_arrangeByWidthAscending = !_arrangeByWidthAscending;
					_project.arrangeImagesByWidth(_arrangeByWidthAscending);
					break;
				case ACTION_ARRANGE_BY_HEIGHT :
					_arrangeByHeightAscending = !_arrangeByHeightAscending;
					_project.arrangeImagesByHeight(_arrangeByHeightAscending);
					break;
				case ACTION_ARRANGE_BY_COMPLEX_WIDTH :
					_arrangeByWidthComplexAscending = !_arrangeByWidthComplexAscending;
					_project.arrangeImagesByComplexWidth(_arrangeByWidthComplexAscending);
					break;
				case ACTION_ARRANGE_BY_COMPLEX_HEIGHT :
					_arrangeByHeightComplexAscending = !_arrangeByHeightComplexAscending;
					_project.arrangeImagesByComplexHeight(_arrangeByHeightComplexAscending);
					break;
				case ACTION_ARRANGE_MIN_SPACING :
					n = 1.0;
					switch(label) {
						case "1px" :
							n = 1.0;
							break;
						case "2px" :
							n = 2.0;
							break;
						case "3px" :
							n = 3.0;
							break;
						case "4px" :
							n = 4.0;
							break;
						case "5px" :
							n = 5.0;
							break;
					}
					_project.arrangeMinSpacing = n;
					break;
				case 15 :
					_project.selector.addListeners();
					break;
			}
		}
		protected function createFileReference():void {
			if(_fileReference != null) {
				destroyFileReference();
			}
			_fileReference = new FileReference();
			_fileReference.addEventListener(Event.CANCEL, fileReferenceCancelEvent, false, 0, false);
			_fileReference.addEventListener(Event.SELECT, fileReferenceSelectEvent, false, 0, false);
			_fileReference.addEventListener(Event.COMPLETE, fileReferenceCompleteEvent, false, 0, false);
		}
		protected function destroyFileReference():void {
			if(_fileReference == null) {
				return;
			}
			_fileReference.removeEventListener(Event.CANCEL, fileReferenceCancelEvent);
			_fileReference.removeEventListener(Event.SELECT, fileReferenceSelectEvent);
			_fileReference.removeEventListener(Event.COMPLETE, fileReferenceCompleteEvent);
			_fileReference = null;
		}
		protected function fileReferenceCancelEvent(pEvent:Event):void {
			destroyFileReference();
			_action = -1;
		}
		protected function fileReferenceSelectEvent(pEvent:Event):void {
			switch(_action) {
				case ACTION_LOAD_PROJECT :
					_fileReference.load();
					break;
				case ACTION_SAVE_PROJECT :
					// DO NOTHING ON SELECT
					break;
				case ACTION_EXPORT_TEXTURE :
					// DO NOTHING ON SELECT
					break;
				case ACTION_EXPORT_COORDINATES :
					// DO NOTHING ON SELECT
					break;
			}	
		}
		protected function fileReferenceCompleteEvent(pEvent:Event):void {
			switch(_action) {
				case ACTION_LOAD_PROJECT :
					_project.data = _fileReference.data;
					_project.name = _fileReference.name;
					break;
				case ACTION_SAVE_PROJECT :
					_project.name = _fileReference.name;
					break;
				case ACTION_EXPORT_TEXTURE :
					_project.savedTextureName = _fileReference.name;
					break;
				case ACTION_EXPORT_COORDINATES :
					_project.savedCoordinatesName = _fileReference.name;
					break;
			}
			destroyFileReference();
			_action = -1;
		}
		protected function createFileReferenceList():void {
			if(_fileReferenceList != null) {
				destroyFileReferenceList();
			}
			_fileReferenceList = new FileReferenceList();
			_fileReferenceList.addEventListener(Event.CANCEL, fileReferenceListCancelEvent);
			_fileReferenceList.addEventListener(Event.SELECT, fileReferenceListSelectEvent);
		}
		protected function destroyFileReferenceList():void {
			if(_fileReferenceList == null) {
				return;
			}
			_fileReferenceList.removeEventListener(Event.CANCEL, fileReferenceListCancelEvent);
			_fileReferenceList.removeEventListener(Event.SELECT, fileReferenceListSelectEvent);
			_fileReferenceList = null;
		}
		protected function fileReferenceListCancelEvent(pEvent:Event):void {
			destroyFileReferenceList();
		}
		protected function fileReferenceListSelectEvent(pEvent:Event):void {
			_fileList = _fileReferenceList.fileList.slice();
			switch(_action) {
				case ACTION_IMPORT_IMAGES :
					if(_fileList.length > 0) {
						_fileListLoadIndex = 0;
						loadNextFileFromFileReferenceList();
					}
					break;
			}
		}
		private function loadNextFileFromFileReferenceList():void {
			var fileRef:FileReference = _fileList[_fileListLoadIndex];
			fileRef.addEventListener(Event.COMPLETE, loadNextFileFromFileReferenceListCompleteEvent, false, 0, true);
			fileRef.load();
		}
		private function loadNextFileFromFileReferenceListCompleteEvent(pEvent:Event):void {
			_fileListLoadIndex++;
			if(_fileList.length > _fileListLoadIndex) {
				loadNextFileFromFileReferenceList();
			}
			else {
				switch(_action) {
					case ACTION_IMPORT_IMAGES :
						while(_fileList.length > 0) {
							var image:ZTImage = new ZTImage();
							image.loadFromFileReference(_fileList.shift());
							_project.addImage(image);
						}
						destroyFileReferenceList();
						break;
				}
			}
			
		}
	}
}