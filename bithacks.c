// Copyright: Someone on the internet probably, this looks familiar:
// https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
// Claiming fair use. YMMV.
// 
// expects a bit field with a single bit set to high
// returns the index of that bit
unsigned char whichBit(unsigned long long input){
    unsigned long long masks[] = {
        0xaaaaaaaaaaaaaaaa,
        0xcccccccccccccccc,
        0xf0f0f0f0f0f0f0f0,
        0xff00ff00ff00ff00,
        0xffff0000ffff0000,
        0xffffffff00000000
    };
    unsigned char bit = 0;
    for(int i = 0; i < 6; i++) {
        bit += (!(!(input & masks[i]))) << i;
    }
    return bit;
}

