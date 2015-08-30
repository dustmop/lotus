import sys


CHR_FORMAT_SIZE = 8192
ROW_SIZE = 16


class CmdLine(object):
  def __init__(self):
    self.input_chr = []
    self.make_chr = None
    self.input_nt = None
    self.output_nt = None


def get_command_line(args):
  cmdline = CmdLine()
  i = 0
  while i < len(args):
    if args[i] == '-c':
      i += 1
      cmdline.input_chr.append(args[i])
    elif args[i] == '-m':
      i += 1
      cmdline.make_chr = args[i]
    elif args[i] == '-i':
      i += 1
      cmdline.input_nt = args[i]
    elif args[i] == '-o':
      i += 1
      cmdline.output_nt = args[i]
    else:
      raise RuntimeError('Unknown command line param "%s"' % args[i])
    i += 1
  return cmdline


class UnmergableError(StandardError):
  def __init__(self, nametable):
    self.nametable = nametable

  def __str__(self):
    return '<UnmergableError "%s">' % self.nametable


class ChrMerger(object):
  def __init__(self, cmdline):
    self.cmdline = cmdline
    self.chr_resolve_map = {}
    self.chr_resolve_count = 0
    self.fout_chr = None
    self.fout_size = 0
    self.modified_chr = []

  def read_first_file(self):
    fin_chr = open(self.cmdline.input_chr[0], 'rb')
    while True:
      row = fin_chr.read(ROW_SIZE)
      if not row:
        break
      if row == ('\x00' * ROW_SIZE) and self.chr_resolve_count > 0:
        break
      if not row in self.chr_resolve_map:
        self.chr_resolve_map[row] = self.chr_resolve_count
      self.chr_resolve_count += 1
      self.fout_chr.write(row)
      self.fout_size += ROW_SIZE
    fin_chr.close()

  def read_second_file(self):
    fin_chr = open(self.cmdline.input_chr[1], 'rb')
    while True:
      row = fin_chr.read(ROW_SIZE)
      if not row:
        break
      if row in self.chr_resolve_map:
        self.modified_chr.append(self.chr_resolve_map[row])
        continue
      self.chr_resolve_map[row] = self.chr_resolve_count
      self.chr_resolve_count += 1
      self.modified_chr.append(self.chr_resolve_map[row])
      self.fout_chr.write(row)
      self.fout_size += ROW_SIZE
    fin_chr.close()

  def pad_output(self):
    self.fout_chr.write('\x00' * (CHR_FORMAT_SIZE - self.fout_size))

  def update_nametable(self):
    if not self.cmdline.input_nt or not self.cmdline.output_nt:
      return
    fin_nametable = open(self.cmdline.input_nt, 'rb')
    fout_nametable = open(self.cmdline.output_nt, 'wb')
    while True:
      byte = fin_nametable.read(1)
      if not byte:
        break
      val = ord(byte)
      val = self.modified_chr[val]
      if val > 255:
        raise UnmergableError(self.cmdline.input_nt)
      fout_nametable.write(chr(val))
    fin_nametable.close()
    fout_nametable.close()

  def execute(self):
    self.fout_chr = open(self.cmdline.make_chr, 'wb')
    self.read_first_file()
    self.read_second_file()
    self.pad_output()
    self.fout_chr.close()
    self.update_nametable()


def run():
  cmdline = get_command_line(sys.argv[1:])
  merger = ChrMerger(cmdline)
  merger.execute()


if __name__ == '__main__':
  run()
