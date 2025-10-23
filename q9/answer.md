# 1
most of them have the same size (for the file with  uniprot_i.fasta), if we find the sum of all these files, it is the same size to the file size of uniport_sprot. each chunk of these small files are of the similiar size. it looks like the spliting is without any loss, we still can keep the sequence. by doing this we can more easily to do the parallel computation
# 2
## b
```
hmmsearch --cpu 8 --noali -o output.txt Pfam-A.hmm input.fasta
```
The meaning of each parameter in the command is as follows :

- `--cpu 8`: use 8 CPU cores for multithreading
- `--noali`: do not output alignments, so the output file is smaller
- `-o output.txt`: write results to the file output.txt (instead of stdout)
- `Pfam-A.hmm`: the query HMM file
- `input.fasta`: the sequence database
## c
the current code is using the multithreading to parallism it, we can gnu parallel it through gnu through this command:
```
ls uniprot_*.fasta | grep -v "uniprot_sprot.fasta" | \
parallel -j "$threadnumber" hmmsearch --cpu 8 --noali \
  -o {/.}.out Pfam-A.hmm {}

```
which means that it will cut the `input.fasta`  into lots of small fractions, then do the searching on them
### d