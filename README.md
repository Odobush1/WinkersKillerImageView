# WinkersKillerImageView

View detects face on photo or image, using standard iOS face detector library. Result of that action is rectangle around face, mouth and eyes location points, if face exist on photo. Second step is adding blur effect on that mask. It uses GPUImage library for blurring. Than blend blurred image with original one. Now works only with one face on image.

1) imageView?.setOriginalImage(originalImage) //First of all set image with face.

2) imageView?.showHandledImage() //First time handle image and add blur, second time just shows result image.

3) imageView?.showOriginalImage() //Shows original image.

4) imageView?.cleanImageView() //Remove all images before setting new one.