import os
from setuptools import setup, find_packages
from Cython.Build import cythonize

long_description = (
    open('README.rst').read()
    + '\n' +
    open('CHANGES.txt').read())

tests_require = [
    'pytest >= 2.0',
    'pytest-cov'
    ]

setup(name='hireg',
      version='0.2.dev0',
      description="Reg hispeed. Speedups for Reg.",
      long_description=long_description,
      author="Martijn Faassen",
      author_email="faassen@startifact.com",
      license="BSD",
      url='http://reg.readthedocs.org',
      packages=find_packages(),
      include_package_data=True,
      zip_safe=False,
      classifiers=[
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Programming Language :: Python :: 2.7',
        'Development Status :: 4 - Beta'
        ],
      install_requires=[
        'setuptools',
        'reg',
        ],
      ext_modules=cythonize('hireg/mapply.pyx'),
      tests_require=tests_require,
      extras_require = dict(
        test=tests_require,
        )
      )
