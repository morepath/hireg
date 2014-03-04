import inspect


def mapply(func, *args, **kw):
    """Apply keyword arguments to function only if it defines them.

    So this works without error as ``b`` is ignored::

      def foo(a):
          pass

      mapply(foo, a=1, b=2)

    Zope has an mapply that does this but a lot more too. py.test has
    an implementation of getting the argument names for a
    function/method that we've borrowed.
    """
    return cymapply(func, args, kw)

cdef object cymapply(object func, tuple args, dict kw):
    cdef dict new_kw
    cdef CacheEntry info
    info = arginfo(func)
    if info.keywords:
        return func(*args, **kw)
    # XXX we don't support nested arguments
    new_kw = {name: kw[name] for name in info.args if name in kw}
    return func(*args, **new_kw)


cdef dict _arginfo_cache

_arginfo_cache = {}



cdef class CacheEntry:
    cdef tuple args
    cdef int varargs
    cdef int keywords

    def __init__(self, args, varargs, keywords):
        self.args = args
        self.varargs = varargs
        self.keywords = keywords


cdef CacheEntry arginfo(object callable):
    """Get information about the arguments of a callable.

    Returns a :class:`inspect.ArgSpec` object as for
    :func:`inspect.getargspec`.

    :func:`inspect.getargspec` returns information about the arguments
    of a function. arginfo also works for classes and instances with a
    __call__ defined. Unlike getargspec, arginfo treats bound methods
    like functions, so that the self argument is not reported.

    arginfo caches previous calls (except for instances with a
    __call__), making calling it repeatedly cheap.

    This was originally inspired by the pytest.core varnames() function,
    but has been completely rewritten to handle class constructors,
    also show other getarginfo() information, and for readability.
    """
    try:
        return _arginfo_cache[callable]
    except KeyError:
        # Try to get __call__ function from the cache.
        try:
            return _arginfo_cache[callable.__call__]
        except (AttributeError, KeyError):
            pass
    func, cache_key, remove_self = get_callable_info(callable)
    if func is None:
        return inspect.ArgSpec([], None, None, None)
    argspec = inspect.getargspec(func)
    if remove_self:
        args = argspec.args[1:]
        argspec = inspect.ArgSpec(args, argspec.varargs, argspec.keywords,
                                  argspec.defaults)
    result = _arginfo_cache[cache_key] = CacheEntry(
        tuple(argspec.args),
        argspec.varargs is not None,
        argspec.keywords is not None)
    return result


def is_cached(callable):
    if callable in _arginfo_cache:
        return True
    return callable.__call__ in _arginfo_cache


def get_callable_info(callable):
    """Get information about a callable.

    Returns a tuple of:

    * actual function/method that can be inspected with inspect.getargspec.

    * cache key to use to cache results.

    * whether to remove self or not.

    Note that in Python 3, __init__ is not a method, but we still
    want to remove self from it.

    If not inspectable (None, None, False) is returned.
    """
    if inspect.isfunction(callable):
        return callable, callable, False
    if inspect.ismethod(callable):
        return callable, callable, True
    if inspect.isclass(callable):
        return get_class_init(callable), callable, True
    try:
        callable = getattr(callable, '__call__')
        return callable, callable, True
    except AttributeError:
        return None, None, False


def fake_empty_init():
    pass


class Dummy(object):
    pass


WRAPPER_DESCRIPTOR = Dummy.__init__


def get_class_init(class_):
    try:
        func = class_.__init__
    except AttributeError:
        # Python 2 classic class without __init__.
        return fake_empty_init
    # If this is a new-style class and there is no __init__
    # defined, in CPython (but not PyPy) this is a WRAPPER_DESCRIPTOR.
    if func is WRAPPER_DESCRIPTOR:
        return fake_empty_init
    # A PyPy class without __init__ needs to be handled specially,
    # as the default __init__ in this case falsely reports varargs
    # and keywords.
    if is_pypy_default_init(func):
        return fake_empty_init
    return func


def is_pypy_default_init(func):
    try:
        return func.func_code.co_name == 'descr__init__'
    except AttributeError:
        return False
