import sys
import os
import deepdespeckling
import deepdespeckling.denoiser
import deepdespeckling.despeckling
import deepdespeckling.model
import deepdespeckling.utils
import deepdespeckling.utils.constants
import deepdespeckling.utils.load_cosar
import deepdespeckling.utils.utils
import deepdespeckling.sar2sar
import deepdespeckling.sar2sar.sar2sar_denoiser
import deepdespeckling.merlin
import deepdespeckling.merlin.merlin_denoiser

# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

sys.path.insert(0, os.path.abspath('../'))

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'deepdespeckling'
copyright = '2024, Hadrien Mariaccia, Emanuele Delsasso'
author = 'Hadrien Mariaccia, Emanuele Delsasso'
release = '0.3'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx.ext.githubpages'
]

templates_path = ['_templates']
exclude_patterns = ["build", ".venv", ".vscode",
                    "dist", "deepdespeckling.egg-info", "img", "icons"]


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']
