.PHONY: checkallvars checkvars clean zcadenv zcadelectrotechenv version zcad zcadelectrotech cleanzcad cleanzcadelectrotech installpkgstolaz zcadelectrotechpdfuseguide rmpkgslibs tests
default: cleanzcad

ZCVERSION:=$(shell git describe --tags)

OSDETECT:=
ifeq ($(OS),Windows_NT)
	OSDETECT:=WIN32
else
	UNAME_S:=$(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSDETECT=LINUX
	endif
	ifeq ($(UNAME_S),Darwin)
		OSDETECT:=OSX
	endif
endif

CPUDETECT:=
ifeq ($(OS),Windows_NT)
	ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		CPUDETECT=AMD64
	endif
	ifeq ($(PROCESSOR_ARCHITECTURE),x86)
		CPUDETECT=IA32
	endif
else
	UNAME_P := $(shell uname -p)
	ifeq ($(UNAME_P),x86_64)
		CPUDETECT=AMD64
	endif
		ifneq ($(filter %86,$(UNAME_P)),)
	CPUDETECT=IA32
		endif
	ifneq ($(filter arm%,$(UNAME_P)),)
		CPUDETECT=ARM
	endif
endif

PATHDELIM:=
ifeq ($(OSDETECT),WIN32)
	PATHDELIM =\\
else
	PATHDELIM =/
endif


PCP:=
ifeq ($(OSDETECT),WIN32)
	PCP=$(LOCALAPPDATA)\lazarus
else
	ifeq ($(OSDETECT),LINUX)
		PCP='~/.lazarus'
	else
		ifeq ($(OSDETECT),OSX)
			PCP=~/.lazarus
		else
			PCP=~/.lazarus
		endif

	endif
endif

LP:=
ifeq ($(OSDETECT),WIN32)
	LP =C:\lazarus
else
	ifeq ($(OSDETECT),LINUX)
		LP=~/lazarus
	else
		ifeq ($(OSDETECT),OSX)
			PCP=~/lazarus
		else
			PCP=~/lazarus
		endif

	endif
endif

checkallvars: checkvars 
	@echo OSDETECT=$(OSDETECT)
	@echo CPUDETECT=$(CPUDETECT)

checkvars:              
	@echo PCP=$(PCP)
	@echo LP=$(LP)

clean:                  
	rm -rf  cad_source/autogenerated/*
	rm -rf  cad_source/autogenerated
	rm -rf  cad/*
	rm -rf cad
	rm -rf lib/*
	rm -rf errors/*.bak
	rm -rf errors/*.dbpas

updatezcadenv: checkvars      
	rm -rf  cad/blocks
	rm -rf  cad/components
	rm -rf  cad/configs
	rm -rf  cad/examples
	rm -rf  cad/fonts
	rm -rf  cad/images
	rm -rf  cad/languages
	rm -rf  cad/log
	rm -rf  cad/menu
	rm -rf  cad/plugins
	rm -rf  cad/programdb
	rm -rf  cad/template
	cp -r environment/runtimefiles/common/* cad
	cp -r environment/runtimefiles/zcad/* cad

updatezcadelectrotechenv: checkvars      
	rm -rf  cad/blocks
	rm -rf  cad/components
	rm -rf  cad/configs
	rm -rf  cad/examples
	rm -rf  cad/fonts
	rm -rf  cad/images
	rm -rf  cad/languages
	rm -rf  cad/log
	rm -rf  cad/menu
	rm -rf  cad/plugins
	rm -rf  cad/programdb
	rm -rf  cad/template
	cp -r environment/runtimefiles/common/* cad
	cp -r environment/runtimefiles/zcadelectrotech/* cad

zcadenv: checkvars      
	mkdir cad
	mkdir $(subst /,$(PATHDELIM),cad_source/autogenerated)
	cp -r environment/runtimefiles/common/* cad
	cp -r environment/runtimefiles/zcad/* cad
	echo create_file>cad_source/autogenerated/buildmode.inc
	rm -r cad_source/autogenerated/buildmode.inc
	echo {DEFINE ELECTROTECH}>cad_source/autogenerated/buildmode.inc

zcadelectrotechenv: checkvars 
	mkdir cad
	mkdir $(subst /,$(PATHDELIM),cad_source/autogenerated)
	cp -r environment/runtimefiles/common/* cad
	cp -r environment/runtimefiles/zcadelectrotech/* cad
	echo create_file>cad_source/autogenerated/buildmode.inc
	rm -r cad_source/autogenerated/buildmode.inc
ifeq ($(OSDETECT),WIN32)
	echo {$$DEFINE ELECTROTECH}>cad_source/autogenerated/buildmode.inc
else
	echo {\$$DEFINE ELECTROTECH}>cad_source/autogenerated/buildmode.inc
endif

version:                      
	@echo ZCAD Version: $(ZCVERSION)
ifeq ($(OSDETECT),WIN32)
	@echo '$(ZCVERSION)' > cad_source/zcadversion.inc
else
	@echo \'$(ZCVERSION)\' > cad_source/zcadversion.inc
endif
	@echo $(ZCVERSION) > cad_source/zcadversion.txt
	
zcad: checkvars version       
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) cad_source/utils/typeexporter.lpi
	environment/typeexporter/typeexporter pathprefix=cad_source/ outputfile=cad/rtl/system.pas processfiles=environment/typeexporter/zcad.files
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) cad_source/zcad.lpi

zcadelectrotech: checkvars version    
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) cad_source/utils/typeexporter.lpi
	environment/typeexporter/typeexporter pathprefix=cad_source/ outputfile=cad/rtl/system.pas processfiles=environment/typeexporter/zcad.files+environment/typeexporter/zcadelectrotech.files
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) cad_source/zcad.lpi

cad:
	mkdir cad
cad/help:
	mkdir $(subst /,$(PATHDELIM),cad/help)
cad/help/locale:
	mkdir $(subst /,$(PATHDELIM),cad/help/locale)
cad/help/locale/ru:
	mkdir $(subst /,$(PATHDELIM),cad/help/locale/ru)
cad/help/locale/ru/_images:
	mkdir $(subst /,$(PATHDELIM),cad/help/locale/ru/_images)

documentation: checkvars cad cad/help cad/help/locale cad/help/locale/ru cad/help/locale/ru/_images
	$(MAKE) -C cad_source/docs/userguide LP=$(LP) PCP=$(PCP) all
	cp cad_source/docs/userguide/*.html cad/help
	cp cad_source/docs/userguide/*.pdf cad/help
	cp -r cad_source/docs/userguide/locale/ru/_images/* cad/help/locale/ru/_images

tests: checkvars
	$(MAKE) -C cad_source/components/zcontainers/tests LP=$(LP) PCP=$(PCP) clean all
	$(MAKE) -C cad_source/zengine/tests LP=$(LP) PCP=$(PCP) clean all

updatelocalizedpofiles: checkvars
	cp cad/languages/rtzcad.po cad/languages/rtzcad.pot
	$(LP)$(PATHDELIM)tools$(PATHDELIM)updatepofiles cad/languages/rtzcad.pot
	rm -rf cad/languages/rtzcad.pot
	cp $(LP)$(PATHDELIM)lcl/languages/*.po cad/languages
	cp $(LP)$(PATHDELIM)components/anchordocking/languages/*.po cad/languages

cleanzcad: clean zcadenv zcad

cleanzcadelectrotech: clean zcadelectrotechenv zcadelectrotech

rmpkgslibs:
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zcontainers$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zbaseutils$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zbaseutilsgui$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zebase$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zcontrols$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zmacros$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zmath$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zobjectinspector$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zscriptbase$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zscript$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)ztoolbars$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)zundostack$(PATHDELIM)lib$(PATHDELIM)*
	rm -rf  cad_source$(PATHDELIM)components$(PATHDELIM)fpdwg$(PATHDELIM)lib$(PATHDELIM)*

installpkgstolaz: checkvars rmpkgslibs
ifneq ($(OSDETECT),OSX)
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)other$(PATHDELIM)AGraphLaz$(PATHDELIM)lazarus$(PATHDELIM)ag_graph.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)other$(PATHDELIM)AGraphLaz$(PATHDELIM)lazarus$(PATHDELIM)ag_math.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)other$(PATHDELIM)AGraphLaz$(PATHDELIM)lazarus$(PATHDELIM)ag_vectors.lpk
endif
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)other$(PATHDELIM)uniqueinstance$(PATHDELIM)uniqueinstance_package.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zcontainers$(PATHDELIM)zcontainers.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zbaseutils$(PATHDELIM)zbaseutils.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zbaseutilsgui$(PATHDELIM)zbaseutilsgui.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zebase$(PATHDELIM)zebase.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zcontrols$(PATHDELIM)zcontrols.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zmacros$(PATHDELIM)zmacros.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zmath$(PATHDELIM)zmath.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zobjectinspector$(PATHDELIM)zobjectinspector.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zscriptbase$(PATHDELIM)zscriptbase.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zscript$(PATHDELIM)zscript.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)ztoolbars$(PATHDELIM)ztoolbars.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)zundostack$(PATHDELIM)zundostack.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --add-package cad_source$(PATHDELIM)components$(PATHDELIM)fpdwg$(PATHDELIM)fpdwg.lpk
	$(LP)$(PATHDELIM)lazbuild --pcp=$(PCP) --build-ide=""
