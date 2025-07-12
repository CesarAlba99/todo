class Todo
  class TodoError < StandardError
  end

  class TodoFileReadError < TodoError
  end

  class TodoFileWriteError < TodoError
  end

  class InvalidUsernameError < TodoError
  end
end
