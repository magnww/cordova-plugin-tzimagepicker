package com.mjd.tzimagepicker;

import android.app.Activity;
import android.content.Intent;

import com.lzy.imagepicker.ImagePicker;
import com.lzy.imagepicker.bean.ImageItem;
import com.lzy.imagepicker.view.CropImageView;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;

import java.util.List;

public class TZImagePicker extends CordovaPlugin implements TZImagePickerActivity.TZImagePickerListener {

    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, final JSONArray args,
                           final CallbackContext callbackContext) {
        this.callbackContext = callbackContext;
        if ("getPictures".equals(action)) {
            init();

            Activity activity = this.cordova.getActivity();
            Intent intent = new Intent(activity, TZImagePickerActivity.class);
            activity.startActivity(intent);

        } else if ("deleteFile".equals(action)) {
            // TODO
        }
        return true;
    }

    @Override
    public void onGetPictures(List<ImageItem> images) {
        JSONArray result = new JSONArray();
        for (ImageItem image : images) {
            result.put(image.path);
        }
        callbackContext.success(result);
    }

    private void init() {
        TZImagePickerActivity.setEventListener(this);

        ImagePicker imagePicker = ImagePicker.getInstance();
        imagePicker.setImageLoader(new PicassoImageLoader());   //设置图片加载器
        imagePicker.setShowCamera(true);  //显示拍照按钮
        imagePicker.setCrop(true);        //允许裁剪（单选才有效）
        imagePicker.setSaveRectangle(true); //是否按矩形区域保存
        imagePicker.setSelectLimit(9);    //选中数量限制
        imagePicker.setStyle(CropImageView.Style.RECTANGLE);  //裁剪框的形状
        imagePicker.setFocusWidth(800);   //裁剪框的宽度。单位像素（圆形自动取宽高最小值）
        imagePicker.setFocusHeight(800);  //裁剪框的高度。单位像素（圆形自动取宽高最小值）
        imagePicker.setOutPutX(1000);//保存文件的宽度。单位像素
        imagePicker.setOutPutY(1000);//保存文件的高度。单位像素
    }

    private void callJS(final String js) {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                webView.loadUrl("javascript:" + js);
            }
        });
    }
}