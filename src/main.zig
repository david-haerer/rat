const std = @import("std");
const logging = @import("logging.zig");
const io = @import("io.zig");
const Rat = @import("rat.zig").Rat;

pub const std_options = .{ .logFn = logging.logFn };

pub fn main() !void {
    logging.hello();
    var rat = try Rat.init();
    defer rat.cleanup();

    rat.server.move(1920, -1080);
    rat.server.move(-104, 13);
    rat.server.pressButton(io.Button.Left);
    rat.server.releaseButton(io.Button.Left);

    var exit = false;
    var event : c.XEvent = undefined;
    while(!exit) {
        while(c.XPending(rat.server.display)) {
            c.XNextEvent(rat.server.display, &event);            
            
        }
       
        
    }

    // while (rat.running()) {
    //     rat.move();
    //     rat.handleEvents();
    // }
}

static XEvent *get_next_xev(int timeout)
{
	static int xfd = 0;
	static XEvent ev;
	char buf[1024];

	if (XPending(dpy)) {
		XNextEvent(dpy, &ev);
		return &ev;
	}

	fd_set fds;

	if (!xfd)
		xfd = XConnectionNumber(dpy);

	FD_ZERO(&fds);
	FD_SET(xfd, &fds);

	select(xfd + 1, &fds, NULL, NULL,
	       timeout ? &(struct timeval){0, timeout * 1000} : NULL);

	if (XPending(dpy)) {
		XNextEvent(dpy, &ev);
		return &ev;
	} else
		return NULL;
}

struct input_event *x_input_wait(struct input_event *events, size_t sz)
{
	size_t i;
	static struct input_event ev;
	struct input_event *ret = NULL;

	for (i = 0; i < sz; i++) {
		struct input_event *ev = &events[i];
		xgrab_key(ev->code, ev->mods, 1);
	}

	while (1) {
		XEvent *xev = get_next_xev(100);

		if (xev && (xev->type == KeyPress || xev->type == KeyRelease)) {
			ev.code = (uint8_t)xev->xkey.keycode;
			ev.mods = xmods_to_mods(xev->xkey.state);
			ev.pressed = xev->type == KeyPress;

			x_input_grab_keyboard();

			ret = &ev;
			goto exit;
		} else {
			size_t i;
			for (i = 0; i < nr_monitored_files; i++) {
				long mtime = x_get_mtime(monitored_files[i].path);
				if (mtime != monitored_files[i].mtime) {
					monitored_files[i].mtime = mtime;
					goto exit;
				}
			}
		}
	}

exit:
	for (i = 0; i < sz; i++) {
		struct input_event *ev = &events[i];
		xgrab_key(ev->code, ev->mods, 0);
	}

	return ret;
}
