## save the picked patches as .np
import mat73
import numpy as np
from scipy.io import loadmat
import matplotlib.pyplot as plt
import os

path = os.environ.get('SAR_STRIPMAP_ROOT')
if not path:
    raise RuntimeError(
        'Set SAR_STRIPMAP_ROOT to the data1_stripmap source-data directory.'
    )
path = os.path.abspath(path)
savePath = os.path.join(path, 'patches', 'backup')
# for patchIdx in range(1,6):
patchIdx = 5
# load the patch data (.mat)
loadPath_re = os.path.join(savePath, 'SARpatch' + str(patchIdx) + '_re.mat')
py_data_re = mat73.loadmat(loadPath_re)['re']
py_data_re = py_data_re[:, ::-1]

loadPath_im = os.path.join(savePath, 'SARpatch' + str(patchIdx) + '_im.mat')
py_data_im = mat73.loadmat(loadPath_im)['im']
py_data_im = py_data_im[:, ::-1]

# py_data = py_data_re + 1j * py_data_im
## -- Plot the image --
# log_scaled_re = 20 * np.log10(np.abs(py_data_re) / np.max(np.abs(py_data_re)) + 1e-10)
# plt.figure(1)
# plt.imshow(log_scaled_re, cmap='gray', aspect='auto', vmin=-60, vmax=0)
# plt.colorbar()
# plt.axis('off')
#
# log_scaled_im = 20 * np.log10(np.abs(py_data_im) / np.max(np.abs(py_data_im)) + 1e-10)
# plt.figure(2)
# plt.imshow(log_scaled_im, cmap='gray', aspect='auto', vmin=-60, vmax=0)
# plt.colorbar()
# plt.axis('off')
#
# log_scaled = 20 * np.log10(np.abs(py_data) / np.max(np.abs(py_data)) + 1e-10)
# plt.figure(3)
# plt.imshow(log_scaled, cmap='gray', aspect='auto', vmin=-60, vmax=0)
# plt.colorbar()
# plt.axis('off')
# plt.show()

py_data = np.stack((py_data_re, py_data_im), axis=-1)
np.save(os.path.join(savePath, 'patch' + str(patchIdx) + '.npy'), py_data)
print(py_data.shape)


# ## make sure that the preprocessed data save in merlin>processed_images is the same as the original
# import numpy as np
# path1 = '/path/to/stripmap/merlin/processed_images/patch1.npy'
# pyfile1 = np.load(path1)
#
# path2 = '/path/to/stripmap/patches/backup/patch1.npy'
# pyfile2 = np.load(path2)
#
# res = (pyfile1 == pyfile2)
# print(np.sum(res))
