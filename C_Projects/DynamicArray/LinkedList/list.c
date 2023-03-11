/*
 * Name: Zach Taylor
 * Email: taylzach@oregonstate.edu
 */

#include <stdlib.h>

#include "list.h"

/*
 * This structure is used to represent a single link in a singly-linked list.
 */
struct link {
  void* val;
  struct link* next;
};

/*
 * This structure is used to represent an entire singly-linked list.
 */
struct list {
  struct link* head;
};

/*
 * This function should allocate and initialize a new, empty linked list and
 * return a pointer to it.
 */
struct list* list_create() {
  struct list* head_node = malloc(sizeof(struct list));
  head_node->head = NULL;
  return head_node;
}

/*
 * This function should free the memory associated with a linked list.  In
 * particular, while this function should up all memory used in the list
 * itself (i.e. the space allocated for all of the individual links), it should
 * not free any memory allocated to the pointer values stored in the list.  In
 * other words, this function does not need to free the `val` fields of the
 * list's links.
 *
 * Params:
 *   list - the linked list to be destroyed.  May not be NULL.
 */
void list_free(struct list* list) {
  struct link* temp;

  while(list->head != NULL) {
    temp = list->head;
    list->head = list->head->next;
    free(temp);
  }
  free(list);
}

/*
 * This function should insert a new value into a given linked list.
 * Importantly, this function will need to allocate a new `struct link` in
 * which to store the new value and add that link at the head of the list.  For
 * simplicity, this function should only insert elements at the *beginning* of
 * the list.  In other words, it should always insert the new element as the
 * head of the list.
 *
 * Params:
 *   list - the linked list into which to insert an element.  May not be NULL.
 *   val - the value to be inserted.  Note that this parameter has type void*,
 *     which means that a pointer of any type can be passed.
 */
void list_insert(struct list* list, void* val) {
  if(list->head) {
    struct link* node = list->head;
    struct link* new_head = malloc(sizeof(struct link));
    list->head = new_head;
    new_head->val = val;
    list->head->next = node;
  } else {
    list->head = malloc(sizeof(struct link));
    list->head->val = val;
  }
}

/*
 * This function should remove an element with a specified value from a given
 * linked list.  Importantly, if the specified value appears multiple times in
 * the list, the function should only remove the *first* instance of that
 * value (i.e. the one nearest to the head of the list).  For example, if a
 * list stores pointers to integers and contains two instances of the value 4,
 * only the first of those values should be removed, and the other one should
 * remain in the list.  Importantly, this function will also need to free the
 * memory held by the link being removed.
 *
 * Params:
 *   list - the linked list from which to remove an element.  May not be NULL.
 *   val - the value to be removed.  Note that this parameter has type void*,
 *     which means that a pointer of any type can be passed.
 *   cmp - pointer to a function that can be passed two void* values from
 *     to compare them for equality, as described above.  If the two values
 *     passed are to be considered equal, this function should return 0.
 *     Otherwise, it should return a non-zero value.
 */
void list_remove(struct list* list, void* val, int (*cmp)(void* a, void* b)) {
  struct link* previous = list->head;
  struct link* current = list->head->next;

  if(cmp(val, previous->val) == 0) {
    if(list->head == previous) {
      free(list->head);
      list->head = current;
    }
  } else {
    while(cmp(val, current->val) != 0) {
      previous = current;
      current = current->next;
    }
    if(cmp(val, current->val) == 0) {
      previous->next = current->next;
      free(current);
    }
  }
}

/*
 * This function should return the position (i.e. the 0-based "index") of the
 * first instance of a specified value within a given linked list.  For
 * example, if the list contains the specified in the 4th and 8th links
 * starting at the head, then this function should return 3 (the 0-based
 * "index" of the 4th link.).  If the value is contained in the head link,
 * then this function should return 0 (the 0-based index of the head link).
 * If the list does not contain the specified value, then this function should
 * return the special value -1.
 *
 * Params:
 *   list - the linked list from which to remove an element.  May not be NULL.
 *   val - the value to be located.  Note that this parameter has type void*,
 *     which means that a pointer of any type can be passed.
 *   cmp - pointer to a function that can be passed two void* values from
 *     to compare them for equality, as described above.  If the two values
 *     passed are to be considered equal, this function should return 0.
 *     Otherwise, it should return a non-zero value.
 *
 * Return:
 *   This function should return the 0-based position of the first instance of
 *   `val` within `list`, as determined by the function `cmp` (i.e. the closest
 *    such instance to the head of the list) or -1 if `list` does not contain
 *    the value `val`.
 */
int list_position(struct list* list, void* val, int (*cmp)(void* a, void* b)) {
  struct link* current = list->head;
  int i = 0;

  while(current != NULL) {
    if(cmp(val, current->val) == 0) {
      return i;
    }
    current = current->next;
    i++;
  }

  if(current == NULL) {
    return -1;
  }
}

/*
 * This function should reverse the order of the links in a given linked list.
 * The reversal should be done *in place*, i.e. within the existing list, and
 * new memory should not be allocated to accomplish the reversal.
 *
 * Params:
 *   list - the linked list to be reversed.  May not be NULL.  When this
 *     function returns this should contain the reversed list.
 */
void list_reverse(struct list* list) {
  struct link* current = list->head;
  struct link* last = NULL;
  struct link* next = NULL;
  while(current != NULL) {
    next = current->next;
    current->next = last;
    last = current;
    current = next;
  }
  list->head = last;
}
