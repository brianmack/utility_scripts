""" Collate many directories of data into one place as eg. in
picture dump.
"""


import logging
import optparse
import os
import pickle
import re
import subprocess
import sys



HASH_FNAME = "_hashed_files"

FILEHASH = None

def getopt():
    
    parser = optparse.OptionParser()
    parser.add_option("-d", "--debug", dest="debug", action="store_true",
        help="debug mode")
    parser.add_option("-i", "--input-dir", dest="input_dir",
        help="copy files from here and all subdirs to output")
    parser.add_option("-o", "--output-dir", dest="output_dir",
        help="collate files to transfer HERE, also save hashes here")
    parser.add_option("-g", "--ignore", dest="ignore_fname",
        help="file containing patterns to ignore - TODO")
    parser.add_option("-w", "--whitelist", dest="whitelist",
        help="text file listing filetypes to search")
    return parser.parse_args()

def parse_textfile_to_set(fname):
    f = open(fname)
    lines = f.readlines()
    s = set()
    for l in lines:
        l = l.strip()
        l = l.replace(".", "")
        if l:
            s.add(l)
    return s


def test_extension(fname, wl=None, bl=None):
    

    ending = fname.split(".")[-1]
    if wl:
        if ending not in wl:
            return 1
    if bl:
        if ending in bl:
            return 1
    return 0



def main(options):
    
    global FILEHASH


    input_dir = options.input_dir
    output_dir = options.output_dir
    
    try:
        blacklist = parse_textfile_to_set(options.ignore_fname) 
    except TypeError:
        logging.info("no blacklist provided, proceeding without...")
        blacklist = None

    try:
        whitelist = parse_textfile_to_set(options.whitelist)
    except TypeError:
        logging.info("no whitelist provided, proceeding without...")
        whitelist = None

    # restore from current hash if it exists
    hash_pickle_fname = os.path.join(output_dir, HASH_FNAME + ".pkl")
    hash_text_fname = os.path.join(output_dir, HASH_FNAME + ".txt")
    try:
        FILEHASH = pickle.load(open(hash_pickle_fname, "rb"))
    except Exception as e:
        logging.warning("problem loading file {} = {}".format(
            hash_pickle_fname, e))
        # make a new one
        FILEHASH = set()
    
    for (root, dirs, files) in os.walk(input_dir):
        
        root = root.replace(" ", "\ ")

        for fname in files:
            
            if fname == "." or fname == "..":
                logging.debug("skipping dot '.' file")
            
            if test_extension(fname, whitelist, blacklist):
                logging.debug("file {} failed white/blacklist test".format(
                    fname))
                continue
                 
            fname = fname.replace(" ", "\ ") 

            full_path = os.path.join(root, fname)
            
            result = subprocess.check_output("md5 {}".format(full_path),
                shell=True).decode("utf-8")
            hashval = result.strip().split()[-1]
            #logging.info("hasval = {}".format(hashval))
            if hashval in FILEHASH:
                logging.info("already saw {}, skipping...".format(fname))
            else:
                FILEHASH.add(hashval)
                outpath = os.path.join(output_dir, fname)
                # check for duplicates
                if os.path.isfile(outpath):
                    tmp_result = subprocess.check_output("md5 {}".format(
                        outpath), shell=True).decode("utf-8")
                    tmp_hashval = tmp_result.strip().split()[-1]
                    if tmp_hashval == hashval:
                        logging.info("file {} already in output directory, "\
                            "continuing".format(outpath))
                        continue
                    else:
                        logging.warning("File {} already in output directory "\
                            "but has a different hash than the input".format(
                                outpath))
                        outpath += ".dup"
                cmd = "cp {} {}".format(full_path, outpath)
                logging.info("{}".format(cmd))
                os.system(cmd)

    pickle.dump(FILEHASH, open(hash_pickle_fname, "wb"))
    with open(hash_text_fname, "w") as f:
        for item in FILEHASH:
            f.write("{}\n".format(item))

    return


if __name__ == "__main__":
    
    options, _ = getopt()
    
    if options.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)
    
    main(options)

