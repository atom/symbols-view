module A::Foo
  B = 'b'

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
  baz= 1
  baz = 2
  Foo = 3
end
