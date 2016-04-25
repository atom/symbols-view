def Foo
  def bar!

  end

  def bar?

  end

  def baz
  end

  def baz=(*)
  end
end

if bar?
  baz
  bar!
elsif !bar!
  baz=
end
