package com.zwopple.zwoptex {

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;

	public class ZTSorter {
		
		private var _margin:int;
		
		public function ZTSorter(pImages:Array, pAtlasW:int, pAtlasH:int, pMargin:int) {
			//trace("sort atlasW:"+pAtlasW+" atlasH:"+pAtlasH+" margin:"+pMargin);
			_margin = pMargin;
			var baseNode:Object = emptyNode();
			baseNode.left = 0;
			baseNode.bottom = 0;
			baseNode.width = pAtlasW;
			baseNode.height = pAtlasH;
			for(var i:int = 0; i < pImages.length; i++) {
				var image:ZTImage = pImages[i];
				image.x = 0.0;
				image.y = 0.0;
				insertImage(baseNode,image);
			}
			positionNode(baseNode);
		}
		private function insertImage(node:Object, image:ZTImage):Object {
			var newNode:Object;
			
			if(node.childA != null || node.childB != null) {
				newNode = insertImage(node.childA,image);
				if(newNode != null) {
					return newNode;
				}
				newNode = insertImage(node.childB,image);
				if(newNode != null) {
					return newNode;
				}
				return null;
			} else {
				if(node.image != null) {
					return null;
				} else if(image.width > node.width || image.height > node.height) {
					return null;
				} else if(node.width == image.width && node.height == image.height) {
					node.image = image;
					return node;
				}
				
				var childA:Object = emptyNode();
				var childB:Object = emptyNode();
				
				var dw:Number = node.width - image.width;
				var dh:Number = node.height - image.height;
				
				if(dw > dh) {
					childA.left = node.left;
					childA.bottom = node.bottom;
					childA.width = image.width;
					childA.height = node.height;
					
					childB.left = node.left + image.width;
					childB.bottom = node.bottom;
					childB.width = node.width - image.width;
					childB.height = node.height;
				} else {
					childA.left = node.left;
					childA.bottom = node.bottom;
					childA.width = node.width;
					childA.height = image.height;
					
					childB.left = node.left;
					childB.bottom = node.bottom + image.height;
					childB.width = node.width;
					childB.height = node.height - image.height;
				}
				
				node.childA = childA;
				node.childB = childB;
				
				newNode = insertImage(node.childA,image);
				return newNode;
			}
			return null;
		}
		private function emptyNode():Object {
			return {left:0,bottom:0,width:0,height:0,image:null,childA:null,childB:null};
		}
		private function positionNode(node:Object):void {
			if(node.image != null) {
				var px:Number = node.left;
				var py:Number = node.bottom;
				var w:Number = node.image.width;
				var h:Number = node.image.height;
				
				node.image.x = px;
				node.image.y = py;
			}
			if(node.childA != null) {
				positionNode(node.childA);
			}
			if(node.childB != null) {
				positionNode(node.childB);
			}	
		}
	}
}

