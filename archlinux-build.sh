#!/bin/bash

make installpkgstolaz LP=/usr/lib/lazarus PCP=~/.lazarus
make clean
make zcadenv
make zcad LP=/usr/lib/lazarus PCP=~/.lazarus


make clean
make zcadelectrotechenv
make zcadelectrotech  LP=/usr/lib/lazarus PCP=~/.lazarus

