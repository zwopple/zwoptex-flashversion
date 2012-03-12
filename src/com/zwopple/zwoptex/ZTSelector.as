//:: Package ---------------------------------------------------------------------------------------------------------------

package com.zwopple.zwoptex
{
	//:: Imports -----------------------------------------------------------------------------------------------------------
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.net.*;
	import flash.system.*;
	import flash.ui.Keyboard;
	import flash.utils.*;
	
	//:: Class -------------------------------------------------------------------------------------------------------------
	
	public class ZTSelector extends Sprite
	{
		//:: ===============================================================================================================
		//:: Properties ====================================================================================================
		//:: ===============================================================================================================
		
		//:: Public Static Properties --------------------------------------------------------------------------------------
		
		//:: Protected Static Properties -----------------------------------------------------------------------------------
		
		//:: Private Static Properties -------------------------------------------------------------------------------------
		
		//:: Public Properties ---------------------------------------------------------------------------------------------
		
		//:: Protected Properties ------------------------------------------------------------------------------------------
		
		//:: Private Properties --------------------------------------------------------------------------------------------
		
		private var _keysDown:Array;
		private var _project:ZTProject;
		private var _startX:Number = 0;
		private var _startY:Number = 0;
		private var _lastX:Number = 0;
		private var _lastY:Number = 0;
		private var _translating:Boolean = false;
		private var _ignoreMoveUpAndClick:Boolean = false;
		
		//:: ===============================================================================================================
		//:: Constructor ===================================================================================================
		//:: ===============================================================================================================
		
		public function ZTSelector(pProject:ZTProject)
		{
			name = "selector";
			_keysDown = [];
			_project = pProject;
			addEventListener(Event.ADDED_TO_STAGE, addedToStageEvent);
		}
		
		//:: ===============================================================================================================
		//:: Getters & Setter ==============================================================================================
		//:: ===============================================================================================================
		
		//:: Static Getters & Setters --------------------------------------------------------------------------------------
		
		//:: Getters & Setters ---------------------------------------------------------------------------------------------
		
		public function get selectedImages():Array
		{
			var images:Array = _project.images;
			var o:Array = [];
			for(var i:int = 0; i < images.length; i++)
			{
				if(images[i].selected)
				{
					o.push(images[i]);
				}
			}
			return o;
		}
		
		override public function set mouseEnabled(pValue:Boolean):void
		{
			super.mouseEnabled = pValue;
			if(pValue)
			{
				addListeners();
			}
			else
			{
				removeListeners();
				graphics.clear();
			}
		}
		
		//:: ===============================================================================================================
		//:: Methods =======================================================================================================
		//:: ===============================================================================================================
		
		//:: Public Static Methods -----------------------------------------------------------------------------------------
		
		//:: Protected Static Methods --------------------------------------------------------------------------------------
		
		//:: Private Static Methods ----------------------------------------------------------------------------------------
		
		//:: Public Methods ------------------------------------------------------------------------------------------------
		
		//:: Protected Methods ---------------------------------------------------------------------------------------------
		
		//:: Private Methods -----------------------------------------------------------------------------------------------
		
		public function addListeners():void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardEvent, false, 1);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyboardEvent, false, 1);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownEvent, false, 1);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEvent, false, 1);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpEvent, false, 1);
		}
		public function removeListeners():void
		{
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyboardEvent);
			stage.removeEventListener(KeyboardEvent.KEY_UP, keyboardEvent);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownEvent);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEvent);
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpEvent);
		}
		
		private function addedToStageEvent(pEvent:Event):void
		{
			addListeners();
		}
		
		private function mouseDownEvent(pEvent:MouseEvent):void
		{
			var n:String = pEvent.target.name;
			_ignoreMoveUpAndClick = (n != "canvas" && n != "image" && n != "selector");
			if(_ignoreMoveUpAndClick) {
				return;
			}
			
			_startX = mouseX;
			_startY = mouseY;
			_lastX = _startX;
			_lastY = _startY;
			
			if(pEvent.target is ZTImage)
			{
				_translating = true;
				var image:ZTImage = pEvent.target as ZTImage;
				
				if(keyDown(Keyboard.SHIFT))
				{
					_translating = false;
					image.selected = !image.selected;
				}
				else if(!image.selected)
				{
					unselectAllImages();
					image.selected = true;
				}
			}
			else if(!keyDown(Keyboard.SHIFT))
			{
				unselectAllImages();
			}
		}
		
		private function mouseMoveEvent(pEvent:MouseEvent):void
		{
			if(_ignoreMoveUpAndClick) {
				return;
			}
			if(!pEvent.buttonDown)
			{
				return;
			}
			
			if(_translating)
			{
				var dx:Number = mouseX - _lastX;
				var dy:Number = mouseY - _lastY;
				_lastX = mouseX;
				_lastY = mouseY;
				translateSelectedImages(dx,dy);	
			}
			else
			{
				updateSelectionRectangle();
				pEvent.updateAfterEvent();
			}
			
		}
		
		private function mouseUpEvent(pEvent:MouseEvent):void
		{
			if(_ignoreMoveUpAndClick) {
				return;
			}
			if(!_translating)
			{
				var images:Array = _project.images;
				while(images.length > 0)
				{
					var image:ZTImage = images.shift();
					var hitTest:Boolean = image.hitTestObject(this);
					if(keyDown(Keyboard.SHIFT) && !image.selected)
					{
						image.selected = hitTest;
					}
					else if(!keyDown(Keyboard.SHIFT))
					{
						image.selected = hitTest;
					}
				}
				graphics.clear();
			} else {	
				_project.repositionImagesInsideCanvas();
			}
			_translating = false;
		}
		
		private function keyboardEvent(pEvent:KeyboardEvent):void
		{
			if(pEvent.type == KeyboardEvent.KEY_DOWN)
			{
				addKey(pEvent.keyCode);
				var xm:Number = 0.0;
				var ym:Number = 0.0;
				switch(pEvent.keyCode)
				{
					case Keyboard.LEFT :
						xm = -1.0;
						break;
					
					case Keyboard.RIGHT :
						xm = 1.0;
						break;
					
					case Keyboard.UP :
						ym = -1.0;
						break;
					
					case Keyboard.DOWN :
						ym = 1.0;
						break;	
				}
				if(keyDown(Keyboard.SHIFT))
				{
					xm *= 10;
					ym *= 10;
				}
				
				// TRANSLATE HERE
				translateSelectedImages(xm,ym);
				
				_project.repositionImagesInsideCanvas();
				
			}
			else if(pEvent.type == KeyboardEvent.KEY_UP)
			{
				removeKey(pEvent.keyCode);
				if(pEvent.keyCode == Keyboard.DELETE)
				{
					var images:Array = selectedImages;
					while(images.length > 0)
					{
						_project.deleteImage(images.shift());
					}
				}
			}
		}
		
		private function updateSelectionRectangle():void
		{
			var rect:Rectangle = new Rectangle();
			rect.x = (_startX < mouseX) ? _startX : mouseX;
			rect.y = (_startY < mouseY) ? _startY : mouseY;
			rect.width = Math.abs(_startX - mouseX);
			rect.height = Math.abs(_startY - mouseY);	
			graphics.clear();
			graphics.beginFill(0x000000, 0.40);
			graphics.lineStyle(1.5, 0xFFFFFF, 0.65);
			graphics.drawRect(rect.x,rect.y,rect.width,rect.height);
			graphics.endFill();
		}
		
		private function unselectAllImages():void
		{
			var images:Array = selectedImages;
			while(images.length > 0)
			{
				images.shift().selected = false;
			}
		}
		
		private function translateSelectedImages(pX:Number = 0.0, pY:Number = 0.0):void
		{
			var images:Array = selectedImages;
			while(images.length > 0)
			{
				var image:ZTImage = images.shift();
				image.x += pX;
				image.y += pY;
			}
		}
		
		private function addKey(pKeyCode:uint):void
		{
			if(!keyDown(pKeyCode))
			{
				_keysDown.push(pKeyCode);
			}
		}
		private function removeKey(pKeyCode:uint):void
		{
			if(keyDown(pKeyCode))
			{
				_keysDown.splice(_keysDown.indexOf(pKeyCode), 1);
			}
		}
		private function keyDown(pKeyCode:uint):Boolean
		{
			return (_keysDown.indexOf(pKeyCode) != -1);
		}
		private function keysDown(... rest):Boolean
		{
			while(rest.length > 0)
			{
				if(!keyDown(rest.shift()))
				{
					return false;
				}
			}
			return true;	
		}
		
	}
}