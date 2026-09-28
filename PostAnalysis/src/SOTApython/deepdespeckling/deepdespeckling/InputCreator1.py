from deepdespeckling.utils.load_cosar import cos2mat
import numpy as np
from scipy.io import savemat
import matplotlib.pyplot as plt
import os
import h5py

observations_root = os.environ.get('SAR_OBSERVATIONS_ROOT')
if not observations_root:
    raise RuntimeError(
        'Set SAR_OBSERVATIONS_ROOT to the directory containing the '
        'stripmap and spotlight source-data folders.'
    )

dataIdx = 2
if dataIdx == 1:
    dataType = 'data1_stripmap'
    dataName = 'IMAGE_VV_SRA_strip_012.cos'
elif dataIdx == 2:
    dataType = 'spotlight'
    dataName = 'IMAGE_HH_SRA_spot_028.cos'
    # The public experiments use the seaside patches 50 and 388.
path = os.path.join(os.path.abspath(observations_root), dataType)
data_path = os.path.join(path, 'IMAGEDATA')
f = cos2mat(os.path.join(data_path, dataName))
# Reading image in CoSAR format.  ncolumns=10912  nlines=6207
# [:,:,0] contains the real part of the SLC image data
# [:,:,1] contains the imaginary part of the SLC image data
print(f.shape)

## -- save the full map as .mat --
savemat(os.path.join(data_path, 'SARReal.mat'), {'SARReal': f[:, :, 0]})
savemat(os.path.join(data_path, 'SARImag.mat'), {'SARImag': f[:, :, 1]})

## -- save selected patches as .mat --
s0 = f.shape[0] // 256
s1 = f.shape[1] // 256
nPatches = s0 * s1
count = 1
pickList = [50, 388]  # Patches to save

for l in range(s0):
    for c in range(s1):
        # Process only if count is in pickList
        if count in pickList:
            patchRe = f[256 * l:256 * (l + 1), 256 * c:256 * (c + 1), 0]
            patchIm = f[256 * l:256 * (l + 1), 256 * c:256 * (c + 1), 1]
            py_data = f[256 * l:256 * (l + 1), 256 * c:256 * (c + 1), :]

            merlin_path = os.path.join(path, str(count), 'merlin')
            sar2sar_path = os.path.join(path, str(count), 'sar2sar')
            os.makedirs(merlin_path, exist_ok=True)
            os.makedirs(sar2sar_path, exist_ok=True)
            # Prepare the npy files for MERLIN
            np.save(os.path.join(merlin_path, 'cosar.npy'), py_data)
            # Prepare the npy (Intensity) files for SAR2SAR
            np.save(os.path.join(sar2sar_path, 'intensity.npy'), np.sqrt(patchRe ** 2 + patchIm ** 2))
            #print(py_data.shape) # 256x256x2

            # Normalize patchRe and patchIm to [-1, 1]

            patchRe_norm = 0.9 * patchRe / np.max(np.abs(patchRe))
            patchIm_norm = 0.9 * patchIm / np.max(np.abs(patchIm))

            # Ensure single precision
            patchRe_norm = patchRe_norm.astype(np.float32)
            patchIm_norm = patchIm_norm.astype(np.float32)

            patchIQ = patchRe_norm + 1j * patchIm_norm

            # -- Log-scaled visualization of patch --
            log_scaled = 20 * np.log10(np.abs(patchIQ) / np.max(np.abs(patchIQ)) + 1e-10)
            log_scaled = np.clip(log_scaled, -30, 0)  # Clamp to [-30, 0]
            log_scaled = log_scaled / 30 + 1  # Normalize to [0, 1]
            plt.figure()
            plt.imshow(log_scaled, cmap='gray', aspect='auto', vmin=0, vmax=1)
            plt.colorbar()
            plt.axis('off')

            # # Save the PNG image
            # png_filename = os.path.join(path, str(count), f'patch_{count}.png')
            # plt.savefig(png_filename, bbox_inches='tight', pad_inches=0)
            # plt.close()

            # Prepare the mat files for Diffusion Restoration
            # Save (savemat cannot save as 7.3), so run 'convert2mat73.m' afterwards
            savemat(os.path.join(path, str(count), 'observI.mat'), {'observ': patchRe_norm})
            savemat(os.path.join(path, str(count), 'observQ.mat'), {'observ': patchIm_norm})
            savemat(os.path.join(path, str(count), 'observLog.mat'), {'observ': log_scaled})

            print(f"Saved patch {count}: {os.path.join(path, str(count))}")

        count += 1
