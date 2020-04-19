#!/usr/bin/python3
import pysam
import sys
import getopt
import csv


def locate_mutation(cigar, mut_start, read_start, coor_padding, seq_padding):
    # print(cigar, mut_start, read_start, coor_padding, seq_padding)
    if len(cigar) == 0:
        return -1
    (code, num) = cigar.pop(0)
    if code == 0 or code == 7 or code == 8:

        if read_start + coor_padding <= mut_start <= read_start + coor_padding + num:
            return (mut_start - (read_start + coor_padding)) + seq_padding - 1
        else:
            return locate_mutation(cigar=cigar, mut_start=mut_start, read_start=read_start, coor_padding=coor_padding+num, seq_padding= seq_padding+num)

    elif code == 3:

        return locate_mutation(cigar=cigar, mut_start=mut_start, read_start=read_start, coor_padding=coor_padding+num, seq_padding=seq_padding)

    elif code == 1:

        if read_start + coor_padding <= mut_start <= read_start + coor_padding + num:
            return (mut_start - (read_start + coor_padding)) + seq_padding - 1
        else:
            return locate_mutation(cigar=cigar, mut_start=mut_start, read_start=read_start, coor_padding=coor_padding, seq_padding= seq_padding+num)

    elif code == 2:

        if read_start + coor_padding <= mut_start <= read_start + coor_padding + num:
            return (mut_start - (read_start + coor_padding)) + seq_padding - 1
        else:
            return locate_mutation(cigar=cigar, mut_start=mut_start, read_start=read_start, coor_padding=coor_padding+num, seq_padding= seq_padding)

    elif code == 4:

        return locate_mutation(cigar=cigar, mut_start=mut_start, read_start=read_start, coor_padding=coor_padding,
                               seq_padding=seq_padding+num)

    elif code == 5:

        return locate_mutation(cigar=cigar, mut_start=mut_start, read_start=read_start, coor_padding=coor_padding+num,
                               seq_padding=seq_padding)

    elif code == 6:

        return locate_mutation(cigar=cigar, mut_start=mut_start, read_start=read_start, coor_padding=coor_padding,
                               seq_padding=seq_padding)

    else:
        return 0


def get_ex_mut_rate(bam_file, chrom, start, ref, alt, mut_type):
    sam_file = pysam.AlignmentFile(bam_file, "rb")
    read_len = max(len(ref), len(alt))

    try:
        iter_sam = sam_file.fetch(chrom, start-1, start+read_len)
    except ValueError:
        try:
            iter_sam = sam_file.fetch('chr' + chrom, start-1, start+read_len)
        except ValueError as v:
            print("Warning: " + str(chrom) + " not a valid chromosome")
            return {'ref': 'NA', 'alt': 'NA', 'noise': 'NA'}
    ref_cont = 0
    alt_cont = 0
    noise_cont = 0
    read_cont = 0

    try:
        for x in iter_sam:
            read_cont += 1
            # print (x)
            if x.is_duplicate:
                print("Duplicated read")
                # continue
            # if x.is_secondary:
                # print("Secondary read")
                # continue

            read_pos = locate_mutation(cigar=x.cigar, mut_start=start, read_start=x.reference_start, coor_padding=0, seq_padding=0)
            qualities = x.query_qualities
            # print read_pos
            # print qualities
            # print len(qualities)
            if -1 < read_pos <= len(qualities) and qualities is not None and qualities[read_pos - 1] <= 1:
                print('low quality')
                print(qualities[read_pos-1])
                continue
            # print(read_pos)
            if read_pos > -1:
                # print("In range")
                seq = x.query_sequence
                # print(seq[read_pos:read_pos+len(ref)], ref, alt)
                if mut_type == "DEL":
                    if seq[read_pos:read_pos+len(ref)] == ref:
                        ref_cont += 1
                    else:
                        alt_cont += 1
                elif mut_type == 'INS':
                    if seq[read_pos:read_pos+len(ref)] == alt:
                        alt_cont += 1
                    else:
                        ref_cont += 1
                else:
                    if seq[read_pos:read_pos+len(ref)] == ref:
                        ref_cont += 1
                    elif seq[read_pos:read_pos+len(ref)] == alt:
                        alt_cont += 1
                    else:
                        noise_cont += 1

        # print (ref_cont, alt_cont, noise_cont, read_cont)
        sam_file.close()
        return {'ref': ref_cont, 'alt': alt_cont, 'noise': noise_cont}
    except IOError:
        print("Warning: ", bam_file, " is empty")
        return {'ref': 'NA', 'alt': 'NA', 'noise': 'NA'}


def rmafster(argv):
    outputfile = ''
    mutationfile = ''
    sample_map = {}
    sample_map_all = {}
    try:
        if len(argv) < 3:
            print(
                "RMAFster.py -m <mutationfile> [-i <inputfile>:<samplename>] [-a <inputfile>:<samplename>] -o <outputfile>\n" +
                "Option -i only searches for specific mutations in specific samples\n" +
                "Option -a searches all mutations in all samples."
            )
            sys.exit(2)
        opts, args = getopt.getopt(argv, "hm:i:a:o:")

    except getopt.GetoptError:
        print('RMAFster.py -m <mutationfile> [-i <inputfile>:<samplename>] [-a <inputfile>:<samplename>] -o <outputfile>')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print(
                "RMAFster.py -m <mutationfile> [-i <inputfile>:<samplename>] [-a <inputfile>:<samplename>] -o <outputfile>\n" +
                "Option -i only searches for specific mutations in specific samples\n" +
                "Option -a searches all mutations in all samples."
            )

            sys.exit()
        elif opt == '-m':
            mutationfile = arg
        # option -i only searches for specific mutations in specific samples
        elif opt == "-i":
            [f, s] = arg.split(':')
            if f == '' or s == '':
                print("Warning empty input\n")
            else:
                if s in sample_map:
                    print("Warning: multiple files for sample:" + s + ", using last one\n")
                sample_map[s] = f
        elif opt == "-o":
            outputfile = arg
        # option -a searches all mutations in all samples.
        elif opt == "-a":
            [f, s] = arg.split(':')
            if f == '' or s == '':
                print("Warning empty input\n")
            else:
                if s in sample_map_all:
                    print("Warning: multiple files for sample:" + s + ", using last one\n")
                sample_map_all[s] = f

    print('Input files and samples are:')
    for s in sample_map:
        print("Sample: " + s + " File: " + sample_map[s] + "\n")
    for s in sample_map_all:
        print("Sample: " + s + " File: " + sample_map_all[s] + "\n")

    # print('Output file is:')
    # print(outputfile)

    # print('Mutation file is:')
    # print(mutationfile)

    csv.field_size_limit(sys.maxsize)

    with open(mutationfile, 'rt') as csvfile_read, open(outputfile, 'wt') as csvfile_write:
        muts = csv.reader(csvfile_read)
        outwriter = csv.writer(csvfile_write)
        head = next(muts)
        chrom_index = head.index("chr")
        pos_index = head.index("pos")
        ref_index = head.index("ref")
        alt_index = head.index("alt")
        type_index = head.index("var")
        sample_index = head.index("sample_id")
        outwriter.writerow(head + ["ref_alleles", "alt_alleles", "other_alleles"])
        samples_not_found = []
        for m in muts:

            sample = m[sample_index]
            if sample in sample_map:
                # print m
                res = get_ex_mut_rate(sample_map[sample], m[chrom_index], int(m[pos_index]),
                                      m[ref_index], m[alt_index], m[type_index])
                outwriter.writerow(m + [res['ref'], res['alt'], res['noise']])
            else:
                if sample not in samples_not_found:
                    samples_not_found.append(sample)

            for s in sample_map_all:
                m[sample_index] = s
                res = get_ex_mut_rate(sample_map_all[s], m[chrom_index], int(m[pos_index]),
                                      m[ref_index], m[alt_index], m[type_index])
                outwriter.writerow(m + [res['ref'], res['alt'], res['noise']])

    for s in samples_not_found:
        print("Warning: sample " + s + " not in files")

