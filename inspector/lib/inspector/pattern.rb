#!/usr/bin/env ruby

# Pattern that relizes emails. Matches whole lines only
EMAIL_PATTERN = /\A[\w!#\$%&'*+\/=?`{|}~^-]+(?:\.[\w!#\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}\Z/

# Pattern that relizes an email within a line.
ANY_EMAIL_PATTERN = /[\w!#\$%&'*+\/=?`{|}~^-]+(?:\.[\w!#\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}/

# Default pattern scanning whole lines
DEFAULT_PATTERN = /\A.*\Z/

# Pattern that relizes strings between \A and \Z that is beginning of line and
# end of line patterns.
FULL_LINE = /(?<=\\A).*(?=\\Z)/
