module dlib.observer;

import std.socket;
static import dlib.remote;

class Observer
{
    private Socket _a;
    this(Socket s)
    {
        this._a = s;
    }
    void watch(char[] resp)
    {
        this._a.send(resp);
        dlib.remote.close_if_alive(_a);
    }
}
