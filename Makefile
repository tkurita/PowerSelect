PRODUCT := PowerSelect
CONFIG := Release

install: clean
	xcodebuild -workspace '$(PRODUCT).xcworkspace' -scheme $(PRODUCT) -configuration $(CONFIG) install DSTROOT=${HOME}

clean:
	xcodebuild -workspace '$(PRODUCT).xcworkspace' -scheme $(PRODUCT) -configuration $(CONFIG) clean
