echo Building...
./nesasm-fix -l 3 aoc.asm
echo Writing CHR...
python build-fix.py
python sym-fix.py >> aoc.fns
