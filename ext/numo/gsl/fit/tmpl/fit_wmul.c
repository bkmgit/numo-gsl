static void
iter_<%=c_func%>(na_loop_t *const lp)
{
    size_t   n;
    char    *p1,*p2,*p3;
    double  *p4,*p5,*p6;
    ssize_t  s1, s2, s3;

    n = lp->args[0].shape[0];
    INIT_PTR(lp, 0, p1, s1);
    INIT_PTR(lp, 1, p2, s2);
    INIT_PTR(lp, 2, p3, s3);
    p4 = (double*)GET_PTR(lp,3);
    p5 = (double*)GET_PTR(lp,4);
    p6 = (double*)GET_PTR(lp,5);

    <%=func_name%>((double*)p1,s1/sizeof(double),
                   (double*)p2,s2/sizeof(double),
                   (double*)p3,s3/sizeof(double),
                   n,p4,p5,p6);
}

/*
  @overload <%=name%>(<%=args[0][1]%>,<%=args[2][1]%>,<%=args[4][1]%>)
  @param  [DFloat]    <%=args[0][1]%> (input array)
  @param  [DFloat]    <%=args[2][1]%> (input array)
  @param  [DFloat]    <%=args[4][1]%> (input array)
  @return [GSL::Fit::<%=result_class%>] result Struct with members: <%=args[7][1]%>, <%=args[8][1]%>, <%=args[9][1]%>.

  <%=desc%>

*/
static VALUE
<%=c_func(3)%>(VALUE mod, VALUE v1, VALUE v2, VALUE v3)
{
    VALUE r, result;
    ndfunc_arg_in_t ain[3] = {{cDF,1},{cDF,1},{cDF,1}};
    ndfunc_arg_out_t aout[3] = {{cDF,0},{cDF,0},{cDF,0}};
    ndfunc_t ndf = { iter_<%=c_func%>, STRIDE_LOOP_NIP|NDF_EXTRACT,
                     3, 3, ain, aout };
    narray_t *x,*y,*w;

    GetNArray(v1,x);
    GetNArray(v2,y);
    GetNArray(v3,w);
    CHECK_SAME_SIZE_1D_3NARRAY(x,y,w)

    r = na_ndloop(&ndf, 3, v1, v2, v3);
    result = rb_class_new_instance(3, RARRAY_PTR(r), c<%=result_class%>);
    RB_GC_GUARD(r);
    return result;
}
