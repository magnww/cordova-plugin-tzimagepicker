var argscheck = require('cordova/argscheck');
var exec = require('cordova/exec');

function TZImagePickerPlugin() {

};
	
// 获取系统相册图片
TZImagePickerPlugin.prototype.getPictures = function(success, fail, options) {
	exec(success, fail, "TZImagePicker", "getPictures", [options]);
};

// 删除图片
TZImagePickerPlugin.prototype.deleteFile = function(success, fail, filePaths) {
	exec(success, fail, "TZImagePicker", "deleteFile", filePaths);
};

module.exports = new TZImagePickerPlugin();
