import re

def complete(t, opts):
  if t:
    opts = [ m[len(t):] for m in opts if m.startswith(t) ]
  if len(opts) == 1:
    return opts[0]
  return '(' + '|'.join(opts) + ')'


def completeVar(t):
  return complete(t, ['var','let','const'])

def formatTag(argument):
  return " * @param {{}} {0}\n".format(argument)

def jsDoc(tabStop):
  # Currently Ultisnips does not support dynamic tabstops, so we cannot add
  # tabstops to the datatype for these param tags until that feature is added.
  arguments = tabStop.split(',')
  arguments = [argument.strip() for argument in arguments if argument]

  if len(arguments):
    tags = map(formatTag, arguments)
    doc = "/**\n"
    for tag in tags:
      doc += tag
    doc += ' */'
    doc += ''
  else:
    doc = ''

  return doc


def formatVariableName(path):
  lastPart = path.split('/')[-1]
  if lastPart == 'lodash':
    return '_'
  elif lastPart == 'react':
    return 'React'
  elif lastPart == 'jquery':
    return '$'
  else:
    return re.sub(r'[_\-]', '', lastPart)
