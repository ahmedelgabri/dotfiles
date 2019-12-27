# -*- coding: utf-8 -*-
# pylint: disable=missing-docstring,invalid-name,len-as-condition

import os, re, vim, string


def repeat_char(snip, ch):
    comment_char = snip.opt("&commentstring")
    comment_char_len = 0 if comment_char is None else len(comment_char)
    repeated_ch = ch * (int(snip.opt("&tw")) - comment_char_len)

    return (
        comment_char % " " + repeated_ch if not (comment_char is None) else repeated_ch
    )


# https://github.com/honza/vim-snippets/blob/67f54554409660af1b34562906c9feab4e2d9909/pythonx/vimsnippets.py#L61
def _parse_comments(s):
    """ Parses vim's comments option to extract comment format """
    i = iter(s.split(","))

    rv = []
    try:
        while True:
            # get the flags and text of a comment part
            flags, text = next(i).split(":", 1)

            if len(flags) == 0:
                rv.append(("OTHER", text, text, text, ""))
            # parse 3-part comment, but ignore those with O flag
            elif "s" in flags and "O" not in flags:
                ctriple = ["TRIPLE"]
                indent = ""

                if flags[-1] in string.digits:
                    indent = " " * int(flags[-1])
                ctriple.append(text)

                flags, text = next(i).split(":", 1)
                assert flags[0] == "m"
                ctriple.append(text)

                flags, text = next(i).split(":", 1)
                assert flags[0] == "e"
                ctriple.append(text)
                ctriple.append(indent)

                rv.append(ctriple)
            elif "b" in flags:
                if len(text) == 1:
                    rv.insert(0, ("SINGLE_CHAR", text, text, text, ""))
    except StopIteration:
        return rv


def get_comment_format():
    """ Returns a 4-element tuple (first_line, middle_lines, end_line, indent)
    representing the comment format for the current file.

    It first looks at the 'commentstring', if that ends with %s, it uses that.
    Otherwise it parses '&comments' and prefers single character comment
    markers if there are any.
    """
    commentstring = vim.eval("&commentstring")
    if commentstring.endswith("%s"):
        c = commentstring[:-2]
        return (c, c, c, "")
    comments = _parse_comments(vim.eval("&comments"))
    for c in comments:
        if c[0] == "SINGLE_CHAR":
            return c[1:]
    return comments[0][1:]


def make_box(twidth, bwidth=None):
    b, m, e, i = (s.strip() for s in get_comment_format())
    bwidth_inner = bwidth - 3 - max(len(b), len(i + e)) if bwidth else twidth + 2
    sline = b + m + bwidth_inner * m[0] + 2 * m[0]
    nspaces = (bwidth_inner - twidth) // 2
    mlines = i + m + " " + " " * nspaces
    mlinee = " " + " " * (bwidth_inner - twidth - nspaces) + m
    eline = i + m + bwidth_inner * m[0] + 2 * m[0] + e
    return sline, mlines, mlinee, eline


# https://github.com/lencioni/dotfiles/blob/eddc37169fd36648791a395a47e2ead3fcadcb87/.vim/pythonx/snippet_helpers.py
def pascal_case_basename(basename):
    return "".join(x[0].upper() + x[1:] for x in basename.split("_"))


def dasherize_basename(basename):
    return "-".join(filter(None, _convert_camel_case(basename).split("_")))


# http://stackoverflow.com/a/1176023/18986
def _convert_camel_case(string):
    s1 = re.sub("(.)([A-Z][a-z]+)", r"\1-\2", string)
    return re.sub("([a-z0-9])([A-Z])", r"\1-\2", s1).lower()


def _clean_basename(basename):
    return re.sub("(_spec|-test)$", "", basename or "ModuleName")


def path_to_component_name(path, case_fn):
    """
    If path ends in `index.jsx`, this function will
    return the PascalCased directory name. Otherwise,
    it returns the PascalCased filename. This allows me to use my snippets
    with modules that are like `/path/to/module_name.jsx` and modules that
    are like `/path/to/ModuleName/index.jsx`.
    """
    dirname, filename = os.path.split(path)
    basename = os.path.splitext(filename)[0]
    if basename in ["index"]:
        # Pop the last directory name off the dirname
        return case_fn(_clean_basename(os.path.basename(dirname)))

    return case_fn(_clean_basename(basename))


def complete(text, opts):
    if text:
        opts = [m[len(text) :] for m in opts if m.startswith(text)]
        if len(opts) == 1:
            return opts[0]
    if len(opts) > 0:
        return "(" + "|".join(opts) + ")"
    return ""


def formatTag(argument):
    return " * @param {{}} {0}\n".format(argument)


def jsDoc(tabStop):
    """
    Currently Ultisnips does not support dynamic tabstops, so we cannot add
    tabstops to the datatype for these param tags until that feature is added.
    arguments = tabStop.split(',')\
        if tabStop[0] != '{' else tabStop[1:-1].split(',')
    """
    arguments = tabStop.split(",")
    arguments = [argument.strip() for argument in arguments if argument]

    if len(arguments):
        tags = map(formatTag, arguments)
        doc = "/**\n"
        for tag in tags:
            doc += tag
            doc += " */"
            doc += ""
    else:
        doc = ""

    return doc


def formatVariableName(path):
    path = path.split("/")
    lastPart = path[-1]

    try:
        firstPart = path[-2]
    except IndexError:
        firstPart = ""

    deps_map = {
        "lodash": "_",
        "ramda": "R",
        "react": "* as React",
        "react-dom": "ReactDOM",
        "prop-types": "PropTypes",
        "jquery": "$",
        "classnames": "cn",
    }

    if firstPart == "lodash":
        return lastPart

    if lastPart in deps_map:
        return deps_map[lastPart]

    return re.sub(r"[_\-]", "", lastPart)
