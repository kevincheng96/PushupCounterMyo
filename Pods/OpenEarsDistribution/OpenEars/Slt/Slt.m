//
//  Slt.m
//  Slt
//
//  Created by Halle on 8/7/12.
//  Copyright (c) 2012 Politepix. All rights reserved.
//

#import "Slt.h"

@implementation Slt

void unregister_cmu_us_slt(cst_voice *vox);
cst_voice *register_cmu_us_slt(const char *voxdir);

- (void)dealloc {
	unregister_cmu_us_slt(self.voice);
    // release stuff
}

- (instancetype) init {
    if (self = [super init]) {
        self.voice = register_cmu_us_slt(NULL);
		self.target_mean_default = 170.0;
		self.target_stddev_default = 15.0;
        self.duration_stretch_default = 1.0;
    }
    return self;
}

@end

