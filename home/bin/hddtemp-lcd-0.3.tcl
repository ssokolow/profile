#! /bin/sh
# the next line restarts using tclsh \
exec `which tclsh` $0 ${1+"$@"}

if {0} {
hddtemp client for LCDd
Written 2006 by Jannis Achstetter <jannis_achstetter@web.de>

Changelog:

*v0.3:
  - fixed some left-overs from older code

*v0.2:
  - only ask hddtemp if screen active
    (by "ignore*" and "listen*" from LCDd;
    saves some CPU-cycles =D)

*v0.1:
  - Initial release

/Changelog

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
}

## -=- Settings start here -=-

# Delay between updates in ms:
set updatetime 500
set lcddport 13666
set hddtemphost "127.0.0.1"
set hddtempport 7634
# Display-style:
# mode 0 = only device-name + temp
# mode 1 = only hdd-model (for example "Maxtor 6Y080L0" or "ST3160023A") + temp
# mode 2 = combined (useful for 20xX and larger) + temp
set dispmode 2

## -=- Settings end -=-
## You actually don't need to change anything below this line

proc connectlcd {} {
  global lcddport lcdsock

  if {[catch {set lcdsock [socket 127.0.0.1 $lcddport]}]} {
    puts "Error connecting to LCDd on 127.0.0.1:$lcddport"
    cleanexit 1
  }
  fileevent $lcdsock readable [list lcdsockread]

  puts $lcdsock "hello"
  flush $lcdsock
}

proc lcdsockread {} {
  global lcdsock lcdversion lcdwid lcdhgt screenactive

  gets $lcdsock line

  if {$line == ""} {
    puts "LCDd died, so we'll suicide! Bye, bye! BOOM!"
    cleanexit 0
  }

  if {[string match {connect LCD*} $line]} {
    set list [split $line]
    set lcdversion [lindex $line 2]
    set lcdprot [lindex $line 4]
    set lcdwid [lindex $line 7]
    set lcdhgt [lindex $line 9]
    set lcdcwid [lindex $line 11]
    set lcdchgt [lindex $line 13]
    puts $lcdsock "client_set name {hddtemp}"
    puts $lcdsock "screen_add hddtemp"
    puts $lcdsock "screen_set hddtemp name hddtemp"
    puts $lcdsock "widget_add hddtemp title title"
    puts $lcdsock "widget_add hddtemp line1 string"
    puts $lcdsock "widget_add hddtemp line2 string"
    puts $lcdsock "widget_add hddtemp line3 string"
    puts $lcdsock "widget_set hddtemp title {HDD Temps}"
    flush $lcdsock
  }
  if {[string match {ignore*} $line]} {
    set screenactive 0
  }
  if {[string match {listen*} $line]} {
    set screenactive 1
  }
}

proc updatehddtemp {} {
  global hddsock hddtempport hddtemphost screenactive updatetime

  if {$screenactive == 1} {
    if {[catch {set hddsock [socket $hddtemphost $hddtempport]}]} {
      puts "Error connecting to hddtemp on $hddtemphost:$hddtempport"
      cleanexit 1
    }
    fileevent $hddsock readable [list hddsockread]

    flush $hddsock
  } else { after $updatetime {updatehddtemp} }
}

proc hddsockread {} {
  global lcdsock hddsock dispmode lcdwid lcdhgt updatetime

  set line [read $hddsock]
  catch {close $hddsock}

  set list [split $line |]

  for {set i 1} {$i<$lcdhgt} {incr i} {

    if {[lindex $list [expr (($i-1)*5)+1]]!= ""} {
      set device [lindex $list [expr (($i-1)*5)+1]]
      set model [lindex $list [expr (($i-1)*5)+2]]
      set temp [lindex $list [expr (($i-1)*5)+3]]
      set unit [lindex $list [expr (($i-1)*5)+4]]
      switch $dispmode {
        0 {
          set lcdstring "$device"
          set count [expr $lcdwid - [string length $device] - [string length $temp] - [string length $unit] - 1]
          for {set x 0} {$x<$count} {incr x} {
            append lcdstring " "
          }
          append  lcdstring "$temp$unit"
        }
        1 {
          set lcdstring "$model"
          set count [expr $lcdwid - [string length $model] - [string length $temp] - [string length $unit] - 1]
          for {set x 0} {$x<$count} {incr x} {
            append lcdstring " "
          }
          append  lcdstring "$temp$unit"
        }
        2 {
          set lcdstring "$device ("
          set count [expr $lcdwid - [string length $device] - [string length $temp] - [string length $unit] - 5]
          for {set x 0} {$x<$count} {incr x} {
            append lcdstring "[string index $model $x]"
          }
          append  lcdstring ") $temp$unit"
        }
      }
      puts $lcdsock "widget_set hddtemp line$i 1 [expr $i+1] {$lcdstring}"
    }
  }

  flush $lcdsock
  after $updatetime {updatehddtemp}
}

proc cleanexit {exitcode} {
  global hddsock lcdsock
  catch {close $hddsock}
  catch {close $lcdsock}
  exit $exitcode
}

connectlcd
#we have to wait until we know how large the LCD is and the screen is active
vwait lcdwid
vwait screenactive
updatehddtemp

vwait forever
