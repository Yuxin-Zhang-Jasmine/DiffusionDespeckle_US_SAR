# from deepdespeckling.utils.load_cosar import cos2mat
# from deepdespeckling.utils.constants import PATCH_SIZE, STRIDE_SIZE
# from deepdespeckling.merlin.merlin_denoiser import MerlinDenoiser
# from deepdespeckling.utils.utils import save_image_to_png
# import os
# import numpy as np
#
# current_path = os.getcwd()
# # destination_directory = current_path + "/deepdespeckling-main/img/entire/sar2sar_tests"
#
# # Path to one image (cos or npy file)
# image_path = "/path/to/stripmap/IMAGEDATA/IMAGE_VV_SRA_strip_012.cos"
# # Model name, can be "spotlight", "stripmap" or "Sentinel-TOPS"
# model_name = "stripmap"
# image = cos2mat(image_path).astype(np.float32)
# # As an alternative, you can load your image by being sure to put in the following format:
# # The shape of image is [img_height,img_width,2], where image[:,:,0] contains the real part and image[:,:,1] contains the imaginary part of the SLC SAR image.
#
# denoiser = MerlinDenoiser(model_name=model_name, symetrise=False)
# denoised_image = denoiser.denoise_image(image, patch_size=PATCH_SIZE, stride_size=STRIDE_SIZE)

from deepdespeckling.despeckling import despeckle
import argparse
import numpy as np
import os
from scipy.io import savemat
from PIL import Image

def main():
    # ----------------------------------------
    # Preparation
    # ----------------------------------------
    parser = argparse.ArgumentParser()
    # "spotlight", "stripmap" or "Sentinel_TOPS" to select MERLIN model on the
    # right cosar image format or "sar2sar" for SAR2SAR model. Default to "spotlight"
    parser.add_argument('--model_name', type=str, required=True, help='stripmap, spotlight or sar2sar')
    parser.add_argument('--input_data', type=str, required=True, help = 'Path of the folder saving sar images (cos or npy files)')
    parser.add_argument('--output_data', type=str, required=True, help='Folder where results are stored')
    args = parser.parse_args()
    # input_data = "/path/to/stripmap/patches/backup/"
    # output_data = "/path/to/stripmap/merlin/"
    despeckle(args.input_data, args.output_data, model_name=args.model_name, symetrise=False)

    # save as mat in range [0,1]
    if args.model_name == "sar2sar":
        result = Image.open(os.path.join(args.output_data, 'denoised/denoised_intensity.png'))
        #result = np.load(os.path.join(args.output_data, 'denoised/denoised_intensity.npy'))
    else:
        result = Image.open(os.path.join(args.output_data, 'denoised/denoised_full_cosar.png'))
        result = np.float32(np.array(result))
    result = np.abs(result) / np.max(np.abs(result))
    savemat(os.path.join(args.output_data, 'result.mat'), {"result": result})

if __name__ == '__main__':

    main()


# coordinates_dictionnary = {'x_start':441,'y_start':654,'x_end':473,'y_end':686}
# from deepdespeckling.despeckling import despeckle
# image_path = "/path/to/spotlight/IMAGEDATA/sar2sar/"
# destination_directory_sar2sar = "/path/to/output/sar2sar/"
# model_name = "sar2sar"
# despeckle(image_path, destination_directory_sar2sar, model_name=model_name)
