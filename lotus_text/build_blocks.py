from PIL import Image
import collections
import sys


NUM_BLOCKS_Y = 15
NUM_BLOCKS_X = 16
BLOCK_SIZE = 16
TILE_SIZE = 8
COLORS = ['white', 'yellow', 'orange', 'red',
          'pink', 'magenta', 'purple', 'blue',
          'cyan', 'lime', 'green', 'gray']
DISABLED_PALETTE = 0
PARTIAL_PALETTE = 1
ENABLED_PALETTE = 2
SYM_PALETTE = 3

NUMBER_DARK = '404040'
NUMBER_LIGHT = 'c0c0c0'


def pixel_to_color_name(p):
  c = '%02x%02x%02x' % (p[0], p[1], p[2])
  if c == '000000':
    return 'black'
  elif c == 'ffffff':
    return 'white'
  elif c == '808080':
    return 'gray'
  elif c == 'f88f00':
    return 'orange'
  elif c == 'ffff00':
    return 'yellow'
  elif c == '008000':
    return 'green'
  elif c == '00ff00':
    return 'lime'
  elif c == 'ff8080':
    return 'pink'
  elif c == 'ff0000':
    return 'red'
  elif c == '800080':
    return 'purple'
  elif c == '00ffff':
    return 'cyan'
  elif c == 'ff00ff':
    return 'magenta'
  elif c == '0000ff':
    return 'blue'
  else:
    raise RuntimeError('Color not found: %s' % (c,))


def block_color_names(block_y, block_x, pxs):
  y = block_y * BLOCK_SIZE
  x = block_x * BLOCK_SIZE
  p = pixel_to_color_name(pxs[x,y])
  s = pixel_to_color_name(pxs[x+2,y+8])
  if s == 'black' or s == p:
    s = None
  return p, s


def symbol_idx(block_y, block_x, pxs):
  for j in range(2):
    for k in range(2):
      y = block_y * BLOCK_SIZE + j * TILE_SIZE
      x = block_x * BLOCK_SIZE + k * TILE_SIZE
      p = pxs[x+1,y+1]
      c = '%02x%02x%02x' % (p[0], p[1], p[2])
      if c != NUMBER_DARK:
        continue
      row = ''
      for i in range(7):
        p = pxs[x+i+1,y+2]
        c = '%02x%02x%02x' % (p[0], p[1], p[2])
        if c == NUMBER_LIGHT:
          row += '0'
        elif c == NUMBER_DARK:
          row += '1'
        else:
          row += 'x'
      if row == '00100xx':
        return 0, j, k
      elif row == '01010xx':
        return 1, j, k
      elif row == '0101010':
        return 2, j, k
      raise RuntimeError('Error, could not ORC number at "%d","%d"' %
                         (block_y, block_x))
  return None, None, None


def merge_attr_bits(ls):
  curr = None
  bits = 0
  accum = []
  for elem in ls:
    if curr is None:
      curr = elem[0]
      bits = elem[1]
    elif curr == elem[0]:
      bits = bits | elem[1]
    else:
      accum.append([curr, bits])
      curr = elem[0]
      bits = elem[1]
  if not curr is None:
    accum.append([curr, bits])
  return accum


def convert_to_attr_map(ls):
  attr_map = {}
  merged = merge_attr_bits(ls)
  for attr, bits in merged:
    attr_map[attr] = bits
  return attr_map


def run():
  filename = sys.argv[1]
  img = Image.open(filename)
  pxs = img.load()
  color_map = collections.defaultdict(list)
  symbol_map = collections.defaultdict(list)
  sym_sum_y = 0
  sym_sum_x = 0
  sym_sum_n = 0
  # For each attr_group.
  for attr_group_y in range((NUM_BLOCKS_Y / 2) + 1):
    for attr_group_x in range(NUM_BLOCKS_X / 2):
      # For each block within that attr_group.
      for i in range(2):
        for j in range(2):
          block_y = attr_group_y * 2 + i
          block_x = attr_group_x * 2 + j
          if block_y < NUM_BLOCKS_Y:
            (prime, secondary) = block_color_names(block_y, block_x, pxs)
          else:
            # Assume last row is entirely black.
            (prime, secondary) = ('black', None)
          attr_offset = attr_group_y * 8 + attr_group_x
          bit_pos = (i * 2 + j) * 2
          color_map[prime].append([attr_offset, ENABLED_PALETTE << bit_pos])
          if block_y < NUM_BLOCKS_Y:
            idx, offset_y, offset_x = symbol_idx(block_y, block_x, pxs)
            if not idx is None:
              tile_y = offset_y + block_y * 2
              tile_x = offset_x + block_x * 2
              symbol_map[prime].append([idx, tile_y, tile_x])
              if idx == 0:
                sym_sum_y += tile_y
                sym_sum_x += tile_x
                sym_sum_n += 1
          if secondary:
            color_map[secondary].append(
              [attr_offset, PARTIAL_PALETTE << bit_pos])
  color_order = ['white', 'yellow', 'orange', 'red',
                 'pink', 'magenta', 'purple', 'blue',
                 'cyan', 'lime', 'green', 'gray']
  for c in color_order:
    sys.stdout.write('%s:\n' % c)
    attr_bits = merge_attr_bits(color_map[c])
    for n in range(4):
      sys.stdout.write('.byte ' if n == 0 else ',')
      (attr, bits) = attr_bits[n] if n < len(attr_bits) else (0,0)
      if attr:
        attr += 0xc0
      sys.stdout.write('$%02x,$%02x' % (attr, bits))
    sys.stdout.write('\n')
  sys.stdout.write('control:\n')
  vals = [(sym_sum_y / sym_sum_n) * 8 - 1,(sym_sum_x / sym_sum_n) * 8,
          (sym_sum_y / sym_sum_n) * 8 - 1,(sym_sum_x / sym_sum_n) * 8 + 0x10,
          (sym_sum_y / sym_sum_n) * 8 + 0xf,(sym_sum_x / sym_sum_n) * 8 + 8,
          0, 0]
  sys.stdout.write('.byte %s\n' % ','.join(['$%02x' % e for e in vals]))
  for c in color_order:
    sym_data = symbol_map[c]
    sym_data.sort()
    sys.stdout.write('%s_symbols:\n' % c)
    sys.stdout.write('.byte ')
    for (idx, tile_y, tile_x) in sym_data:
      sys.stdout.write('$%02x,$%02x,' % (tile_y * 8 - 1, tile_x * 8))
    sys.stdout.write('$00,$00\n')

if __name__ == '__main__':
  run()
